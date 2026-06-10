extends Screen

class_name RewardChoiceScreen

const hud_character_view_scene = preload("res://ui/hud_character_view.tscn")
const skill_tree_scene = preload("res://ui/skill_tree.tscn")

signal continue_pressed
# Internal: fired by the "pick a character" sub-flow when a card is clicked.
signal _character_picked(gc: GameplayCharacter)
# Internal: fired when the player closes the trainer overlay.
signal _trainer_done

var _save_state: SaveState
var _run_save_state: RunSaveState
var _stage_rewards: StageRewards
var _character_cards: Array[HudCharacterView] = []

func _on_show(info: Dictionary):
	_save_state = info.save_state
	_run_save_state = info.run_save_state
	_stage_rewards = info.stage_rewards
	%Title.text = info.get("title", "Choose Your Reward")
	%Prompt.text = ""
	%Outcome.text = ""
	%Continue.hide()
	%TrainerOverlay.hide()
	_build_character_cards()
	_build_set_buttons()

func _build_character_cards():
	for child in %CharacterCards.get_children():
		child.queue_free()
	_character_cards.clear()
	var lib: RelicLibrary = _run_save_state.level_provider.relic_library
	for gc in _run_save_state.gameplay_characters:
		var card := hud_character_view_scene.instantiate() as HudCharacterView
		%CharacterCards.add_child(card)
		card.initialize_from_gameplay_character(gc, lib)
		card.card_clicked.connect(_on_card_clicked)
		_character_cards.append(card)

# Re-init each card from its GameplayCharacter — called by reward applies
# after they mutate state (HP changed, relic added, XP spent).
func refresh_character_cards() -> void:
	var lib: RelicLibrary = _run_save_state.level_provider.relic_library
	for i in _character_cards.size():
		_character_cards[i].initialize_from_gameplay_character(
			_run_save_state.gameplay_characters[i], lib
		)

func _build_set_buttons():
	for child in %SetButtons.get_children():
		child.queue_free()
	for set_idx in _stage_rewards.sets.size():
		var reward_set: RewardSet = _stage_rewards.sets[set_idx]
		var button := Button.new()
		button.text = _set_label(reward_set)
		button.custom_minimum_size = Vector2(200, 60)
		button.pressed.connect(_on_set_pressed.bind(set_idx))
		%SetButtons.add_child(button)

func _set_label(reward_set: RewardSet) -> String:
	var lines: PackedStringArray = []
	for r in reward_set.rewards:
		var name := r.display_name if not r.display_name.is_empty() else "Reward"
		var line := name
		if not r.description.is_empty():
			line += "\n%s" % r.description
		lines.append(line)
	return "\n".join(lines)

func _on_set_pressed(set_idx: int) -> void:
	for b in %SetButtons.get_children():
		(b as Button).disabled = true
	var reward_set: RewardSet = _stage_rewards.sets[set_idx]
	var outcomes: PackedStringArray = []
	for offer in reward_set.rewards:
		var outcome: String = await offer.apply_and_get_outcome(_run_save_state, self)
		if not outcome.is_empty():
			outcomes.append(outcome)
	refresh_character_cards()
	%Outcome.text = "\n\n".join(outcomes)
	%Continue.show()

# --- Sub-flows used by interactive reward types ---

## Make the character cards clickable, await a click, return the chosen
## GameplayCharacter. Used by RelicRewardDef.
func prompt_pick_character(prompt: String) -> GameplayCharacter:
	%Prompt.text = prompt
	for card in _character_cards:
		card.set_pickable(true)
	var gc: GameplayCharacter = await _character_picked
	for card in _character_cards:
		card.set_pickable(false)
	%Prompt.text = ""
	return gc

func _on_card_clicked(gc: GameplayCharacter) -> void:
	# Only relevant during prompt_pick_character; harmless otherwise.
	_character_picked.emit(gc)

## Show the trainer overlay (per-character skill purchases), await Done.
## Used by TrainerRewardDef.
func run_trainer() -> void:
	%TrainerOverlay.show()
	_populate_trainer_buttons()
	await _trainer_done
	%TrainerOverlay.hide()

func _populate_trainer_buttons() -> void:
	for child in %TrainerCharacterList.get_children():
		child.queue_free()
	# Clear any leftover skill tree.
	for child in %TrainerSkillTreeSlot.get_children():
		child.queue_free()
	%TrainerCharacterList.show()
	%TrainerSkillTreeSlot.hide()
	for gc in _run_save_state.gameplay_characters:
		var button := Button.new()
		button.text = "%s (XP: %d)" % [gc.name, gc.xp]
		button.pressed.connect(_open_trainer_for_character.bind(gc))
		%TrainerCharacterList.add_child(button)

func _open_trainer_for_character(gc: GameplayCharacter) -> void:
	%TrainerCharacterList.hide()
	%TrainerSkillTreeSlot.show()
	var skill_tree := skill_tree_scene.instantiate() as SkillTreeUI
	skill_tree.initialize(SkillTreeUI.Mode.ACQUIRE, _save_state, gc, false)
	skill_tree.ok_pressed.connect(_on_trainer_skill_tree_done.bind(skill_tree))
	%TrainerSkillTreeSlot.add_child(skill_tree)

func _on_trainer_skill_tree_done(skill_tree: Control) -> void:
	skill_tree.queue_free()
	refresh_character_cards()
	_populate_trainer_buttons()

func _on_trainer_done_pressed() -> void:
	_trainer_done.emit()

func _on_continue_pressed() -> void:
	continue_pressed.emit()
