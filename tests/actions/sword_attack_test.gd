extends GutTest

# Level has 1 enemy.
const basic_test_level_scene = preload("res://tests/actions/basic_test_level.tscn")
const test_character = preload("res://character/playable_characters/test_character.tres")
const sword_attack = preload("res://skill_tree/actions/sword_attack.tres")
const move_to = preload("res://skill_tree/actions/move_to.tres")
const enemy_target = preload("res://skill_tree/targets/enemy.tres")

var level: Level
var character: Node2D
var character_behavior: BehaviorComponent
var enemy: Node2D
var enemy_health: HealthComponent

func make_sword_behavior(move: bool = false) -> StoredBehavior:
	var behavior = StoredBehavior.new()
	behavior.stored_rules.append(
		TestUtils.rule_def(enemy_target, sword_attack)
	)
	if move:
		behavior.stored_rules.append(
			TestUtils.rule_def(enemy_target, move_to),
		)
	return behavior

func before_each():
	level = basic_test_level_scene.instantiate()
	level.initialize([test_character])
	add_child_autoqfree(level)
	# Set up character.
	character = level.characters.get_child(0)
	character_behavior = Component.get_behavior_component_or_die(character)
	# Set up enemy.
	enemy = level.enemies.get_child(0)
	Component.get_behavior_component_or_die(enemy).stored_behavior = StoredBehavior.new()
	enemy_health = Component.get_health_component_or_die(enemy)

func test_sword_works_within_distance():
	# Basic sword attack only behavior.
	TestUtils.set_character_behavior(character, make_sword_behavior())

	# Put the enemy close to the character.
	enemy.position = character.position + Vector2.RIGHT * 30

	level.start()

	watch_signals(character_behavior)
	await wait_for_signal(enemy_health.died, 3, "Waiting for enemy to die")
	assert_signal_emitted(character_behavior, "behavior_updated")
	assert_signal_emitted(enemy_health, "died")

func test_sword_doesnt_work_out_of_distance():
	# Basic sword attack only behavior.
	TestUtils.set_character_behavior(character, make_sword_behavior())

	# Put the enemy far from the character.
	enemy.position = character.position + Vector2.RIGHT * 100

	level.start()

	watch_signals(character_behavior)
	watch_signals(enemy_health)
	await wait_seconds(3, "Waiting to confirm enemy doesn't die, behavior doesn't change")
	assert_signal_not_emitted(character_behavior, "behavior_updated")
	assert_signal_not_emitted(enemy_health, "died")

func test_move_and_sword_works_out_of_distance():
	# Sword attack with move fallback.
	TestUtils.set_character_behavior(character, make_sword_behavior(true))

	# Put the enemy far from the character.
	enemy.position = character.position + Vector2.RIGHT * 100

	level.start()

	watch_signals(character_behavior)
	await wait_for_signal(enemy_health.died, 4, "Waiting for enemy to die")
	assert_signal_emitted(character_behavior, "behavior_updated")
	assert_signal_emitted(enemy_health, "died")
