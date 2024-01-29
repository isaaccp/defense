extends GutTest

# Level has 1 enemy.
const basic_test_level_scene = preload("res://tests/actions/basic_test_level.tscn")
const enemy_scene = preload("res://enemies/orc_warrior/orc_warrior.tscn")
const test_character = preload("res://character/playable_characters/test_character.tres")
const hold_person = preload("res://skill_tree/actions/hold_person.tres")
const enemy_target = preload("res://skill_tree/targets/enemy.tres")

var level: Level
var character: Node2D
var character_behavior: BehaviorComponent
var enemy: Node2D
var enemy_behavior: BehaviorComponent
var enemy_status: StatusComponent
var enemy_effects: EffectActuatorComponent

func make_hold_person_behavior() -> StoredBehavior:
	var behavior = StoredBehavior.new()
	behavior.stored_rules.append(
		TestUtils.rule_def(enemy_target, hold_person)
	)
	return behavior

func before_each():
	level = basic_test_level_scene.instantiate()
	level.initialize([test_character])
	add_child_autoqfree(level)
	# Set up character.
	character = level.characters.get_child(0)
	character_behavior = BehaviorComponent.get_or_die(character)
	enemy = level.enemies.get_child(0)
	enemy.global_position = character.global_position + Vector2(100, 0)
	enemy_behavior = enemy.get_component_or_die(BehaviorComponent)
	enemy_status = enemy.get_component_or_die(StatusComponent)
	enemy_effects = enemy.get_component_or_die(EffectActuatorComponent)

func test_hold_person_works():
	TestUtils.set_character_behavior(character, make_hold_person_behavior())

	await wait_frames(1)

	level.start()
	watch_signals(character_behavior)
	watch_signals(enemy_behavior)
	watch_signals(enemy_status)
	watch_signals(enemy_effects)

	await wait_for_signal(enemy_status.status_added, 1.0)
	await wait_frames(1)
	assert_signal_emit_count(enemy_behavior, "behavior_updated", 2)
	assert_signal_emitted(enemy_status, "status_added")
	assert_signal_emitted_with_parameters(enemy_effects, "able_to_act_changed", [false])
	assert_false(enemy_behavior.able_to_act)

	await wait_for_signal(enemy_status.status_removed, 5.5)
	assert_signal_emitted(enemy_status, "status_removed")
	assert_signal_emitted_with_parameters(enemy_effects, "able_to_act_changed", [true])
	assert_true(enemy_behavior.able_to_act)
	await wait_frames(1)
	assert_signal_emit_count(enemy_behavior, "behavior_updated", 3)

	TestUtils.dump_all_emits(self, character_behavior, "behavior_updated")
	TestUtils.dump_all_emits(self, enemy_status, "status_added")
	TestUtils.dump_all_emits(self, enemy_effects, "able_to_act_changed")
	TestUtils.dump_all_emits(self, enemy_behavior, "behavior_updated")
