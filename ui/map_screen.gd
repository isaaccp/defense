extends Screen

class_name MapScreen

const hud_character_view_scene = preload("res://ui/hud_character_view.tscn")
const skill_tree_scene = preload("res://ui/skill_tree.tscn")
const map_graph_scene = preload("res://ui/map_graph.gd") # Note: map_graph is just a script, we'll instantiate it

signal continue_pressed
signal _character_picked(gc: GameplayCharacter)
signal _trainer_outcome(picked: GameplayCharacter)
signal reward_state_changed

var _save_state: SaveState
var _run_save_state: RunSaveState
var _stage_rewards: StageRewards
var _character_cards: Array[HudCharacterView] = []
var _has_claimed_any_reward: bool = false
var _apply_context: _ScreenApplyContext

@onready var map_graph: MapGraph = %MapGraph
@onready var hover_panel: PanelContainer = %HoverPanel
@onready var hover_title: Label = %HoverTitle
@onready var hover_desc: Label = %HoverDesc

func _on_show(info: Dictionary):
	_save_state = info.save_state
	_run_save_state = info.run_save_state
	_stage_rewards = info.stage_rewards
	_has_claimed_any_reward = false
	_apply_context = _ScreenApplyContext.new(self)
	
	var base_title: String = info.get("title", "Choose Your Path")
	if _run_save_state and _run_save_state.level_provider:
		%Title.text = "Stage %d of %d: %s" % [
			_run_save_state.current_stage,
			_run_save_state.level_provider.total_stages,
			base_title
		]
	else:
		%Title.text = base_title

	%Prompt.text = "Click a path to select your route for the next battle."
	%RelicReveal.text = ""
	%Continue.hide()
	%Continue.disabled = false
	%SkillTreeOverlay.hide()
	%TrainerControls.hide()
	hover_panel.hide()
	
	_build_character_cards()
	_build_map()

func _build_character_cards() -> void:
	for child in %CharacterCards.get_children():
		child.queue_free()
	_character_cards.clear()
	var lib: RelicLibrary = _run_save_state.level_provider.relic_library
	for gc in _run_save_state.gameplay_characters:
		var card := hud_character_view_scene.instantiate() as HudCharacterView
		card.size_flags_horizontal = Control.SIZE_FILL
		card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		%CharacterCards.add_child(card)
		card.initialize_from_gameplay_character(gc, lib)
		card.card_clicked.connect(_on_card_clicked)
		_character_cards.append(card)

func refresh_character_cards() -> void:
	var lib: RelicLibrary = _run_save_state.level_provider.relic_library
	for i in _character_cards.size():
		_character_cards[i].initialize_from_gameplay_character(
			_run_save_state.gameplay_characters[i], lib
		)

func _build_map() -> void:
	if not map_graph.node_clicked.is_connected(_on_node_clicked):
		map_graph.node_clicked.connect(_on_node_clicked)
		map_graph.node_hovered.connect(_on_node_hovered)
		map_graph.node_unhovered.connect(_on_node_unhovered)
		map_graph.path_locked.connect(_on_path_locked)
	
	map_graph.setup(_stage_rewards)
	if _run_save_state.reward_path_chosen != -1:
		map_graph.restore_state(_run_save_state.reward_path_chosen, _run_save_state.reward_nodes_claimed)
		if not _run_save_state.reward_nodes_claimed.is_empty():
			_has_claimed_any_reward = true

func _on_node_hovered(node: RewardNode) -> void:
	if node.is_next_stage:
		hover_title.text = "Next Battle"
		hover_desc.text = "Face the enemies of Stage %d." % (_run_save_state.current_stage)
	else:
		hover_title.text = node.reward.display_name
		hover_desc.text = node.reward.description
	hover_panel.show()

func _on_node_unhovered(_node: RewardNode) -> void:
	hover_panel.hide()

func _on_node_clicked(node: RewardNode) -> void:
	if not _has_claimed_any_reward and not node.is_next_stage:
		_has_claimed_any_reward = true
	
	if node.is_next_stage:
		_on_continue_pressed()
		return
		
	if %InputBlocker:
		%InputBlocker.show()
		
	node.set_state(RewardNode.State.IN_PROGRESS)
	var outcome: String = await node.reward.apply_and_get_outcome(
		_run_save_state.level_provider.relic_library,
		_run_save_state.gameplay_characters,
		_apply_context
	)
	node.set_state(RewardNode.State.DONE)
	
	# Save progress
	var nodes_in_path = map_graph.get_nodes_in_path(map_graph.get_chosen_path_idx())
	var node_idx = nodes_in_path.find(node)
	if node_idx != -1 and not _run_save_state.reward_nodes_claimed.has(node_idx):
		_run_save_state.reward_nodes_claimed.append(node_idx)
	reward_state_changed.emit()
	
	refresh_character_cards()
	map_graph.update_all_nodes()
	
	if %InputBlocker:
		%InputBlocker.hide()
	
	if not outcome.is_empty():
		%Outcome.text = outcome
		
	_check_all_done()

func _check_all_done() -> void:
	var chosen = map_graph.get_chosen_path_idx()
	if chosen == -1:
		return
	var nodes = map_graph.get_nodes_in_path(chosen)
	for node in nodes:
		if node.state != RewardNode.State.DONE:
			return
	%Prompt.text = "All rewards claimed. Click the battle node to proceed."

func _on_path_locked(_path_idx: int) -> void:
	_run_save_state.reward_path_chosen = _path_idx
	reward_state_changed.emit()
	%Prompt.text = "Path locked. Claim your rewards, or click the battle node to proceed."

# --- Sub-flows used by interactive reward types ---

func prompt_pick_character_for_relic(relic_name: String, relic_description: String) -> GameplayCharacter:
	var info := "[b]You found: %s[/b]" % relic_name
	if not relic_description.is_empty():
		info += "\n%s" % relic_description
	info += "\n\n[i]Click a character to receive it.[/i]"
	%RelicReveal.text = info
	var gc: GameplayCharacter = await _await_character_pick()
	_show_floater_on_card_for_gc(gc, "+ " + relic_name, Color(0.95, 0.85, 0.3, 1))
	return gc

func _await_character_pick() -> GameplayCharacter:
	for card in _character_cards:
		card.set_pickable(true)
	var gc: GameplayCharacter = await _character_picked
	for card in _character_cards:
		card.set_pickable(false)
	%RelicReveal.text = ""
	_pulse_card_for_gc(gc)
	return gc

func _on_card_clicked(gc: GameplayCharacter) -> void:
	_character_picked.emit(gc)

func _gc_index(gc: GameplayCharacter) -> int:
	for i in _run_save_state.gameplay_characters.size():
		if _run_save_state.gameplay_characters[i] == gc:
			return i
	return -1

func _pulse_card_for_gc(gc: GameplayCharacter) -> void:
	var i := _gc_index(gc)
	if i < 0:
		return
	var card := _character_cards[i]
	var tween := create_tween()
	tween.tween_property(card, "modulate", Color(1.6, 1.6, 1.2, 1), 0.12)
	tween.tween_property(card, "modulate", Color.WHITE, 0.32)

func _show_floater_on_card(card: Control, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(label)
	label.position = Vector2(card.size.x / 2.0 - 30.0, -4.0)
	var tween := create_tween()
	tween.parallel().tween_property(label, "position:y", -34.0, 1.1)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.1)
	tween.tween_callback(label.queue_free)

func _show_floater_on_card_for_gc(gc: GameplayCharacter, text: String, color: Color) -> void:
	var i := _gc_index(gc)
	if i < 0:
		return
	_show_floater_on_card(_character_cards[i], text, color)

func flash_hp_floaters(deltas: Dictionary[GameplayCharacter, int]) -> void:
	for gc in deltas.keys():
		var delta: int = deltas[gc]
		if delta <= 0:
			continue
		_show_floater_on_card_for_gc(gc, "+%d HP" % delta, Color(0.55, 1.0, 0.55, 1))

func run_trainer() -> void:
	%TrainerControls.show()
	%Prompt.text = "Click a character to train, or click Finish when done."
	while true:
		var picked: GameplayCharacter = await _wait_for_trainer_outcome()
		if picked == null:
			break
		await _open_skill_tree_for(picked)
		%Prompt.text = "Click another character, or click Finish when done."
	%TrainerControls.hide()
	%Prompt.text = ""

func _wait_for_trainer_outcome() -> GameplayCharacter:
	for card in _character_cards:
		card.set_pickable(true)
	var on_pick := func(gc: GameplayCharacter) -> void: _trainer_outcome.emit(gc)
	_character_picked.connect(on_pick)
	var picked: GameplayCharacter = await _trainer_outcome
	_character_picked.disconnect(on_pick)
	for card in _character_cards:
		card.set_pickable(false)
	return picked

func _open_skill_tree_for(gc: GameplayCharacter) -> void:
	%SkillTreeOverlay.show()
	for child in %SkillTreeSlot.get_children():
		child.queue_free()
	var skill_tree := skill_tree_scene.instantiate() as SkillTreeUI
	skill_tree.initialize(SkillTreeUI.Mode.ACQUIRE, _save_state, _run_save_state.level_provider, gc, false)
	%SkillTreeSlot.add_child(skill_tree)
	await skill_tree.ok_pressed
	skill_tree.queue_free()
	%SkillTreeOverlay.hide()
	refresh_character_cards()

func _on_trainer_finish_pressed() -> void:
	_trainer_outcome.emit(null)

func _on_continue_pressed() -> void:
	var chosen = map_graph.get_chosen_path_idx()
	if chosen != -1:
		var has_unclaimed := false
		for node in map_graph.get_nodes_in_path(chosen):
			if node.state != RewardNode.State.DONE:
				has_unclaimed = true
				break
		if has_unclaimed:
			_show_continue_confirmation()
			return
	continue_pressed.emit()

func _show_continue_confirmation() -> void:
	var confirm_dialog := ConfirmationDialog.new()
	confirm_dialog.title = "Unclaimed Rewards"
	confirm_dialog.dialog_text = "You are leaving rewards behind — proceed to battle?"
	confirm_dialog.get_ok_button().text = "Proceed"
	confirm_dialog.confirmed.connect(func():
		continue_pressed.emit()
		confirm_dialog.queue_free()
	)
	confirm_dialog.canceled.connect(func():
		confirm_dialog.queue_free()
	)
	add_child(confirm_dialog)
	confirm_dialog.popup_centered()

class _ScreenApplyContext extends RewardApplyContext:
	var screen: MapScreen

	func _init(screen_: MapScreen) -> void:
		screen = screen_

	func prompt_pick_character_for_relic(name: String, desc: String) -> GameplayCharacter:
		return await screen.prompt_pick_character_for_relic(name, desc)

	func run_trainer() -> void:
		await screen.run_trainer()

	func flash_hp_floaters(deltas: Dictionary[GameplayCharacter, int]) -> void:
		screen.flash_hp_floaters(deltas)
