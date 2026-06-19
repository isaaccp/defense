extends GutTest

# Level has 1 chest at (160, 100); character spawns at (100, 100). The chest
# yields the default 25 gold when opened.
const chest_test_level_scene = preload("res://tests/integration/actions/chest_test_level.tscn")
const test_character = preload("res://character/playable_characters/test_character.tres")
const open_action = preload("res://skill_tree/actions/open.tres")
const move_to = preload("res://skill_tree/actions/move_to.tres")
const interactable_target_src = preload("res://skill_tree/targets/interactable.tres")

var level: Level
var character: Node2D

func before_each():
	level = chest_test_level_scene.instantiate()
	var unlocked_skills = SkillTreeState.new()
	unlocked_skills.mark_available(preload("res://skill_tree/meta_skills/gold_chests.tres"))
	level.initialize([test_character], unlocked_skills)
	add_child_autoqfree(level)
	character = level.characters.get_child(0)

func _chest_target() -> TargetSelectionDef:
	# Clone the shared resource so test mutations of `params.interactable_kind`
	# don't bleed into other tests / future load uses.
	var target := interactable_target_src.duplicate(true) as TargetSelectionDef
	target.params.set_placeholder_value(SkillParams.PlaceholderId.INTERACTABLE_KIND, Enum.InteractableKind.CHEST)
	return target

func test_character_opens_chest_and_gold_is_emitted():
	var chest_target := _chest_target()
	var behavior := StoredBehavior.new()
	# Move to the chest, then once in range Open fires (smaller distance gates).
	behavior.stored_rules.append(TestUtils.rule_def(chest_target, open_action))
	behavior.stored_rules.append(TestUtils.rule_def(chest_target, move_to))
	TestUtils.set_character_behavior(character, behavior)

	watch_signals(level)
	level.start()

	await wait_for_signal(level.gold_earned, 6, "Waiting for chest to be opened")
	assert_signal_emitted(level, "gold_earned")
	var params = get_signal_parameters(level, "gold_earned")
	assert_eq(params[0], 25, "Chest should yield its default 25 gold")
