extends GutTest

const empty_level_scene = preload("res://tests/actions/empty_level.tscn")
const test_character = preload("res://character/playable_characters/test_character.tres")
const move_away_action = preload("res://skill_tree/actions/move_away.tres")
const enemy_target = preload("res://skill_tree/targets/enemy.tres")

var level: Level
var character: Node2D
var character_behavior: BehaviorComponent

func make_move_away_behavior(max_dist: float = -1.0) -> StoredBehavior:
	var behavior = StoredBehavior.new()
	var action = move_away_action.duplicate(true) as ActionDef
	if max_dist >= 0.0:
		action.params.float_value = FloatValue.make(max_dist)
	behavior.stored_rules.append(TestUtils.rule_def(enemy_target, action))
	return behavior

func before_each():
	test_character.initialize("test_character", 1)
	level = empty_level_scene.instantiate()
	level.initialize([test_character])
	add_child_autoqfree(level)
	character = level.characters.get_child(0)
	character_behavior = character.get_component_or_die(BehaviorComponent)

func test_triggers_when_enemy_within_max_distance():
	TestUtils.set_character_behavior(character, make_move_away_behavior(120.0))
	var target = TestUtils.make_barrel()
	level.enemies.add_child(target)
	target.position = character.position + Vector2.RIGHT * 80
	level.start()
	watch_signals(character_behavior)
	await wait_for_signal(character_behavior.behavior_updated, 1.0, "Waiting for Move Away to trigger")
	TestUtils.assert_last_action(self, character_behavior, move_away_action.skill_name)

func test_does_not_trigger_beyond_max_distance():
	TestUtils.set_character_behavior(character, make_move_away_behavior(120.0))
	var target = TestUtils.make_barrel()
	level.enemies.add_child(target)
	target.position = character.position + Vector2.RIGHT * 200
	level.start()
	watch_signals(character_behavior)
	await wait_seconds(0.5, "Confirming Move Away does not trigger")
	assert_signal_not_emitted(character_behavior, "behavior_updated")

func test_triggers_for_distant_enemy_when_no_max_distance_set():
	# Without float_value configured, max_distance stays at Action.MaxDistance.
	TestUtils.set_character_behavior(character, make_move_away_behavior())
	var target = TestUtils.make_barrel()
	level.enemies.add_child(target)
	target.position = character.position + Vector2.RIGHT * 400
	level.start()
	watch_signals(character_behavior)
	await wait_for_signal(character_behavior.behavior_updated, 1.0, "Waiting for Move Away to trigger")
	TestUtils.assert_last_action(self, character_behavior, move_away_action.skill_name)
