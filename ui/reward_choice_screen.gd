extends Screen

class_name RewardChoiceScreen

const hud_character_view_scene = preload("res://ui/hud_character_view.tscn")
const skill_tree_scene = preload("res://ui/skill_tree.tscn")

signal continue_pressed
# Internal: fired by the character-pick sub-flow when a card is clicked.
signal _character_picked(gc: GameplayCharacter)
# Internal: trainer flow uses these to wait for either a character pick OR
# the Finish button press. `_trainer_outcome` carries the chosen character
# (or null when Finish is pressed).
signal _trainer_outcome(picked: GameplayCharacter)

var _save_state: SaveState
var _run_save_state: RunSaveState
var _stage_rewards: StageRewards
var _character_cards: Array[HudCharacterView] = []
var _set_panels: Array[RewardSetPanel] = []
var _chosen_set_idx: int = -1
var _has_claimed_any_reward: bool = false
# Used during a relic recipient prompt — when null no pick is in progress.
var _picking_for_card: RewardCard
# Adapter passed to reward defs so they don't see this Control directly.
var _apply_context: _ScreenApplyContext

func _on_show(info: Dictionary):
	_save_state = info.save_state
	_run_save_state = info.run_save_state
	_stage_rewards = info.stage_rewards
	_chosen_set_idx = -1
	_has_claimed_any_reward = false
	_apply_context = _ScreenApplyContext.new(self)
	
	var base_title: String = info.get("title", "Choose Your Reward")
	if _run_save_state and _run_save_state.level_provider:
		%Title.text = "Stage %d of %d: %s" % [
			_run_save_state.current_stage,
			_run_save_state.level_provider.total_stages,
			base_title
		]
	else:
		%Title.text = base_title

	%Prompt.text = "Click a reward set to commit. You can claim its rewards in any order."
	%RelicReveal.text = ""
	%Continue.hide()
	%Continue.disabled = false
	%SkillTreeOverlay.hide()
	%TrainerControls.hide()
	_build_character_cards()
	_build_set_panels()

func _build_character_cards() -> void:
	for child in %CharacterCards.get_children():
		child.queue_free()
	_character_cards.clear()
	var lib: RelicLibrary = _run_save_state.level_provider.relic_library
	for gc in _run_save_state.gameplay_characters:
		var card := hud_character_view_scene.instantiate() as HudCharacterView
		# Don't let the cards stretch the column wider than the column wants.
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

func _build_set_panels() -> void:
	for child in %SetPanels.get_children():
		child.queue_free()
	_set_panels.clear()
	for set_idx in _stage_rewards.sets.size():
		var reward_set: RewardSet = _stage_rewards.sets[set_idx]
		var panel := RewardSetPanel.new(self, set_idx, reward_set)
		%SetPanels.add_child(panel)
		_set_panels.append(panel)

# Called by a RewardSetPanel when the player clicks one of its set buttons.
func on_set_chosen(set_idx: int) -> void:
	if _has_claimed_any_reward:
		return  # already locked in
	_chosen_set_idx = set_idx
	for i in _set_panels.size():
		_set_panels[i].set_chosen(i == set_idx)
	%Prompt.text = "Claim each reward by clicking it. Order doesn't matter."
	%Continue.show()
	_check_all_done()

# Called by a RewardCard when the player clicks it.
func on_reward_card_clicked(card: RewardCard) -> void:
	if _chosen_set_idx == -1:
		return
	if not _has_claimed_any_reward:
		_has_claimed_any_reward = true
		for i in _set_panels.size():
			_set_panels[i].lock_in(i == _chosen_set_idx)
	card.set_state(RewardCard.State.IN_PROGRESS)
	%Continue.disabled = true
	var outcome: String = await card.reward.apply_and_get_outcome(
		_run_save_state.level_provider.relic_library,
		_run_save_state.gameplay_characters,
		_apply_context
	)
	card.set_state(RewardCard.State.DONE)
	%Continue.disabled = false
	refresh_character_cards()
	if not outcome.is_empty():
		%Outcome.text = outcome
	_check_all_done()

func _check_all_done() -> void:
	if _chosen_set_idx == -1:
		return
	for card in _set_panels[_chosen_set_idx].cards:
		if card.state != RewardCard.State.DONE:
			return
	%Prompt.text = "All rewards claimed."
	%Continue.show()

# --- Sub-flows used by interactive reward types ---

## Reveal the rolled relic + description, then make character cards
## clickable. Returns the chosen GameplayCharacter. Used by RelicRewardDef.
func prompt_pick_character_for_relic(relic_name: String, relic_description: String) -> GameplayCharacter:
	var info := "[b]You found: %s[/b]" % relic_name
	if not relic_description.is_empty():
		info += "\n%s" % relic_description
	info += "\n\n[i]Click a character to receive it.[/i]"
	%RelicReveal.text = info
	var gc: GameplayCharacter = await _await_character_pick()
	_show_floater_on_card_for_gc(gc, "+ " + relic_name, Color(0.95, 0.85, 0.3, 1))
	return gc

# Generic character pick: makes cards clickable + waits for one. Used as the
# core of prompt_pick_character_for_relic and any future "pick a recipient"
# flows.
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
	# Only relevant during a pick sub-flow; harmless otherwise.
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

# Floats a label upward from the top of `card`, fading out. Used to call
# attention to deltas (HP changes, relic gained, etc.) that would otherwise
# silently update via the card refresh.
func _show_floater_on_card(card: Control, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(label)
	# Center horizontally near the top of the card.
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

## Called by RestRewardDef after it computes per-character heal amounts.
func flash_hp_floaters(deltas: Dictionary[GameplayCharacter, int]) -> void:
	for gc in deltas.keys():
		var delta: int = deltas[gc]
		if delta <= 0:
			continue
		_show_floater_on_card_for_gc(gc, "+%d HP" % delta, Color(0.55, 1.0, 0.55, 1))

## Run the trainer flow: repeatedly let the player pick a character via the
## existing left-side cards, open the skill tree overlay for that character,
## return when they press Finish.
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

# Routes `_character_picked` and the Finish button press into the same
# `_trainer_outcome` signal so the run loop can await one place.
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
	if _chosen_set_idx != -1:
		var has_unclaimed := false
		for card in _set_panels[_chosen_set_idx].cards:
			if card.state != RewardCard.State.DONE:
				has_unclaimed = true
				break
		if has_unclaimed:
			_show_continue_confirmation()
			return
	continue_pressed.emit()

func _show_continue_confirmation() -> void:
	var confirm_dialog := ConfirmationDialog.new()
	confirm_dialog.title = "Unclaimed Rewards"
	confirm_dialog.dialog_text = "You are leaving rewards behind — proceed?"
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

# ============================================================================
# RewardSetPanel — one of the choice columns; holds its reward cards.
# ============================================================================
class RewardSetPanel extends PanelContainer:
	var screen: RewardChoiceScreen
	var set_idx: int
	var reward_set: RewardSet
	var cards: Array[RewardCard] = []
	var _title_label: Label
	var _choose_button: Button
	var _cards_row: HBoxContainer

	func _init(screen_: RewardChoiceScreen, set_idx_: int, reward_set_: RewardSet):
		screen = screen_
		set_idx = set_idx_
		reward_set = reward_set_
		size_flags_horizontal = SIZE_EXPAND_FILL
		var vb := VBoxContainer.new()
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		add_child(margin)
		margin.add_child(vb)
		var header := HBoxContainer.new()
		vb.add_child(header)
		_title_label = Label.new()
		_title_label.text = "Choice %s" % char("A".unicode_at(0) + set_idx)
		_title_label.add_theme_font_size_override("font_size", 14)
		_title_label.size_flags_horizontal = SIZE_EXPAND_FILL
		header.add_child(_title_label)
		_choose_button = Button.new()
		_choose_button.text = "Choose"
		_choose_button.pressed.connect(_on_choose)
		header.add_child(_choose_button)
		_cards_row = HBoxContainer.new()
		_cards_row.add_theme_constant_override("separation", 8)
		_cards_row.size_flags_vertical = SIZE_EXPAND_FILL
		vb.add_child(_cards_row)
		for r in reward_set.rewards:
			var card := RewardCard.new(screen, r)
			_cards_row.add_child(card)
			cards.append(card)
		_apply_style(false)

	func set_chosen(chosen: bool) -> void:
		_choose_button.visible = not chosen
		if chosen:
			_apply_style(true)
			for c in cards:
				c.set_state(RewardCard.State.PENDING)
		else:
			_apply_style(false)
			for c in cards:
				c.set_state(RewardCard.State.PRECHOICE)

	func lock_in(chosen: bool) -> void:
		_choose_button.visible = false
		if chosen:
			_apply_style(true)
		else:
			_apply_style_greyed()
			for c in cards:
				c.set_state(RewardCard.State.GREYED)

	func _apply_style(chosen: bool) -> void:
		modulate = Color.WHITE
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.14, 0.16, 0.22, 1.0) if not chosen else Color(0.16, 0.22, 0.18, 1.0)
		sb.border_color = Color(0.55, 0.55, 0.65, 1.0) if not chosen else Color(0.50, 0.85, 0.50, 1.0)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(6)
		add_theme_stylebox_override("panel", sb)

	func _apply_style_greyed() -> void:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.10, 0.10, 0.12, 1.0)
		sb.border_color = Color(0.30, 0.30, 0.32, 1.0)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(6)
		add_theme_stylebox_override("panel", sb)
		modulate = Color(0.6, 0.6, 0.6, 0.85)

	func _on_choose() -> void:
		screen.on_set_chosen(set_idx)

# ============================================================================
# RewardCard — one reward inside a set.
# ============================================================================
class RewardCard extends PanelContainer:
	enum State { PRECHOICE, PENDING, IN_PROGRESS, DONE, GREYED }
	var screen: RewardChoiceScreen
	var reward: RewardDef
	var state: int = State.PRECHOICE
	var _title: Label
	var _description: Label
	var _badge: Label

	func _init(screen_: RewardChoiceScreen, reward_: RewardDef):
		screen = screen_
		reward = reward_
		custom_minimum_size = Vector2(190, 88)
		mouse_filter = Control.MOUSE_FILTER_STOP
		gui_input.connect(_on_input)
		var margin := MarginContainer.new()
		margin.anchor_right = 1.0
		margin.anchor_bottom = 1.0
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_top", 6)
		margin.add_theme_constant_override("margin_bottom", 6)
		add_child(margin)
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 4)
		margin.add_child(vb)
		_title = Label.new()
		_title.add_theme_font_size_override("font_size", 13)
		_title.text = reward.display_name
		vb.add_child(_title)
		_description = Label.new()
		_description.add_theme_font_size_override("font_size", 10)
		_description.add_theme_color_override("font_color", Color(1, 1, 1, 0.78))
		_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_description.size_flags_vertical = SIZE_EXPAND_FILL
		_description.text = reward.description
		vb.add_child(_description)
		_badge = Label.new()
		_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_badge.add_theme_font_size_override("font_size", 14)
		_badge.visible = false
		vb.add_child(_badge)
		_refresh()

	func set_state(s: int) -> void:
		state = s
		_refresh()

	func _refresh() -> void:
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(5)
		sb.set_border_width_all(2)
		match state:
			State.PRECHOICE:
				sb.bg_color = Color(0.18, 0.22, 0.28, 1.0)
				sb.border_color = Color(0.55, 0.55, 0.65, 1.0)
				_badge.visible = false
				modulate = Color.WHITE
			State.PENDING:
				sb.bg_color = Color(0.18, 0.28, 0.20, 1.0)
				sb.border_color = Color(0.60, 0.90, 0.55, 1.0)
				_badge.text = "Click to claim"
				_badge.add_theme_color_override("font_color", Color(0.65, 0.95, 0.55, 1))
				_badge.visible = true
				modulate = Color.WHITE
			State.IN_PROGRESS:
				sb.bg_color = Color(0.30, 0.25, 0.10, 1.0)
				sb.border_color = Color(0.95, 0.80, 0.30, 1.0)
				_badge.text = "..."
				_badge.add_theme_color_override("font_color", Color(0.95, 0.80, 0.30, 1))
				_badge.visible = true
				modulate = Color.WHITE
			State.DONE:
				sb.bg_color = Color(0.14, 0.20, 0.14, 1.0)
				sb.border_color = Color(0.40, 0.60, 0.40, 1.0)
				_badge.text = "✓ Done"
				_badge.add_theme_color_override("font_color", Color(0.55, 0.95, 0.55, 1))
				_badge.visible = true
				modulate = Color(0.85, 1.0, 0.85, 1.0)
			State.GREYED:
				sb.bg_color = Color(0.10, 0.10, 0.12, 1.0)
				sb.border_color = Color(0.28, 0.28, 0.30, 1.0)
				_badge.visible = false
				modulate = Color(0.45, 0.45, 0.45, 0.8)
		add_theme_stylebox_override("panel", sb)

	func _on_input(event: InputEvent) -> void:
		if state != State.PENDING:
			return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			screen.on_reward_card_clicked(self)

# ============================================================================
# _ScreenApplyContext — adapter handed to reward defs. Forwards the small
# typed surface they need back to the screen, so rewards don't depend on
# the Control class.
# ============================================================================
class _ScreenApplyContext extends RewardApplyContext:
	var screen: RewardChoiceScreen

	func _init(screen_: RewardChoiceScreen) -> void:
		screen = screen_

	func prompt_pick_character_for_relic(name: String, desc: String) -> GameplayCharacter:
		return await screen.prompt_pick_character_for_relic(name, desc)

	func run_trainer() -> void:
		await screen.run_trainer()

	func flash_hp_floaters(deltas: Dictionary[GameplayCharacter, int]) -> void:
		screen.flash_hp_floaters(deltas)
