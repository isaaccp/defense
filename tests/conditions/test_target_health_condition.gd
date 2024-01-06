extends GutTest

const empty_level_scene = preload("res://tests/actions/empty_level.tscn")
const behavior = preload("res://tests/conditions/test_heal_self_under_20_behavior.tres")
const test_character = preload("res://character/playable_characters/test_character.tres")

var level: Level
var character: Node2D
var character_behavior: BehaviorComponent
var character_health: HealthComponent

func before_each():
	level = empty_level_scene.instantiate()
	level.initialize([test_character])
	add_child_autoqfree(level)
	# Set up character.
	character = level.characters.get_child(0)
	character_behavior = Component.get_behavior_component_or_die(character)
	character_health = Component.get_health_component_or_die(character)

func test_no_heal_if_over_20():
	TestUtils.set_character_behavior(character, behavior)
	await wait_frames(1)
	character_health.max_health = 40
	character_health.health = 30
	level.start()
	watch_signals(character_behavior)
	await wait_seconds(0.25, "Waiting to make sure no heal")
	assert_signal_not_emitted(character_behavior, "behavior_updated")

func test_heal_if_under_20():
	TestUtils.set_character_behavior(character, behavior)
	await wait_frames(1)
	character_health.max_health = 40
	character_health.health = 15
	level.start()
	watch_signals(character_behavior)
	await wait_for_signal(character_behavior.behavior_updated, 0.25, "Waiting for heal")
	assert_signal_emitted(character_behavior, "behavior_updated")
