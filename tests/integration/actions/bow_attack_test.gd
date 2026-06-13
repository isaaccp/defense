extends GutTest

const empty_level_scene = preload("res://tests/integration/actions/empty_level.tscn")
const test_character = preload("res://character/playable_characters/test_character.tres")
const bow_attack_action = preload("res://skill_tree/actions/bow_attack.tres")
const move_away_action = preload("res://skill_tree/actions/move_away.tres")
const move_to_action = preload("res://skill_tree/actions/move_to.tres")
const enemy_target = preload("res://skill_tree/targets/enemy.tres")

var level: Level
var character: Node2D
var character_behavior: BehaviorComponent

# Mirrors the orc_archer behavior: bow attack at range, flee when too close,
# close distance when too far.
func make_archer_behavior() -> StoredBehavior:
	var behavior = StoredBehavior.new()
	behavior.stored_rules.append(TestUtils.rule_def(enemy_target, bow_attack_action))
	var limited_move_away = move_away_action.duplicate(true) as ActionDef
	limited_move_away.params.float_value = FloatValue.make(120.0)
	behavior.stored_rules.append(TestUtils.rule_def(enemy_target, limited_move_away))
	behavior.stored_rules.append(TestUtils.rule_def(enemy_target, move_to_action))
	return behavior

func before_each():
	test_character.initialize("test_character", 1)
	level = empty_level_scene.instantiate()
	level.initialize([test_character])
	add_child_autoqfree(level)
	character = level.characters.get_child(0)
	character_behavior = character.get_component_or_die(BehaviorComponent)

func test_bow_attack_fires_at_valid_range():
	TestUtils.set_character_behavior(character, make_archer_behavior())
	var target = TestUtils.make_barrel(10)
	level.enemies.add_child(target)
	target.position = character.position + Vector2.RIGHT * 150
	level.start()
	watch_signals(character_behavior)
	await wait_for_signal(character_behavior.behavior_updated, 2.0, "Waiting for Bow Attack")
	TestUtils.assert_last_action(self, character_behavior, bow_attack_action.skill_name)

func test_move_away_fires_when_enemy_too_close_for_bow():
	TestUtils.set_character_behavior(character, make_archer_behavior())
	var target = TestUtils.make_barrel()
	level.enemies.add_child(target)
	target.position = character.position + Vector2.RIGHT * 50
	level.start()
	watch_signals(character_behavior)
	await wait_for_signal(character_behavior.behavior_updated, 1.0, "Waiting for Move Away")
	TestUtils.assert_last_action(self, character_behavior, move_away_action.skill_name)

func test_move_to_fires_when_enemy_out_of_bow_range():
	TestUtils.set_character_behavior(character, make_archer_behavior())
	var target = TestUtils.make_barrel()
	level.enemies.add_child(target)
	target.position = character.position + Vector2.RIGHT * 400
	level.start()
	watch_signals(character_behavior)
	await wait_for_signal(character_behavior.behavior_updated, 1.0, "Waiting for Move To")
	TestUtils.assert_last_action(self, character_behavior, move_to_action.skill_name)
