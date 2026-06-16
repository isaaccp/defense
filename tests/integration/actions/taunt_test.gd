extends GutTest

const basic_test_level_scene = preload("res://tests/integration/actions/basic_test_level.tscn")
const test_character = preload("res://character/playable_characters/test_character.tres")
const taunt_action = preload("res://skill_tree/actions/taunt.tres")
const enemy_target = preload("res://skill_tree/targets/enemy.tres")
const taunted_status = preload("res://effects/statuses/taunted.tres")

var level: Level
var character: Node2D
var character_behavior: BehaviorComponent
var enemy: Node2D
var enemy_hurtbox: HurtboxComponent
var enemy_status: StatusComponent

func make_taunt_behavior() -> StoredBehavior:
	var behavior = StoredBehavior.new()
	behavior.stored_rules.append(
		TestUtils.rule_def(enemy_target, taunt_action)
	)
	return behavior

func before_each():
	level = basic_test_level_scene.instantiate()
	level.initialize([test_character])
	add_child_autoqfree(level)
	# Set up character.
	character = level.characters.get_child(0)
	character_behavior = Component.get_or_die(character, BehaviorComponent.component) as BehaviorComponent
	# Set up enemy.
	enemy = level.enemies.get_child(0)
	var enemy_bc = Component.get_or_die(enemy, BehaviorComponent.component) as BehaviorComponent
	enemy_bc.stored_behavior = StoredBehavior.new()
	enemy_hurtbox = Component.get_or_die(enemy, HurtboxComponent.component) as HurtboxComponent
	enemy_status = Component.get_or_die(enemy, StatusComponent.component) as StatusComponent

func test_taunt_applies_status():
	TestUtils.set_character_behavior(character, make_taunt_behavior())

	# Put enemy in range
	enemy.position = character.position + Vector2.RIGHT * 40
	level.start()

	watch_signals(character_behavior)
	watch_signals(enemy_status)
	
	await wait_for_signal(enemy_status.status_added, 2, "Waiting for taunted status to be applied")
	
	assert_true(enemy_status.has_status(taunted_status.name), "Enemy should have taunted status")
	var params = enemy_status.get_status_params(taunted_status.name) as TauntedParams
	assert_not_null(params, "TauntedParams should be present")
	assert_eq(params.source_actor, character, "Source actor in params should be the character who taunted")
