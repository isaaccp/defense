extends GutTest

# Level has 1 enemy.
const basic_tower_test_level_scene = preload("res://tests/level/basic_tower_test_level.tscn")

var level: Level
var tower: Node2D
var tower_health: HealthComponent

func before_each():
	level = basic_tower_test_level_scene.instantiate()
	level.initialize([
		GameplayCharacter.make_gameplay_character(Enum.CharacterId.KNIGHT),
		GameplayCharacter.make_gameplay_character(Enum.CharacterId.KNIGHT),
	])
	add_child_autoqfree(level)
	# Set up tower.
	tower = level.towers.get_child(0)
	tower_health = Component.get_health_component_or_die(tower)

func test_tower_destruction_fails_level():
	await wait_for_signal(level.level_failed, 3, "Waiting for level to fail")
	assert_signal_emitted(level, "level_failed")

func test_enemy_destruction_finishes_level():
	# Drop enemies on top of characters so they are easily dispatched.
	level.enemies.get_child(0).position = level.characters.get_child(0).position + Vector2.RIGHT * 50
	level.enemies.get_child(1).position = level.characters.get_child(1).position + Vector2.RIGHT * 50
	await wait_for_signal(level.level_finished, 5, "Waiting for level to finish")
	assert_signal_emitted(level, "level_finished")
