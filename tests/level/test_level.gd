extends GutTest

# Level has 1 enemy.
const basic_tower_test_level_scene = preload("res://tests/level/basic_tower_test_level.tscn")

var level: Level
var tower: Node2D
var tower_health: HealthComponent

func before_each():
	level = basic_tower_test_level_scene.instantiate()
	level.initialize([])
	add_child_autoqfree(level)
	# Set up tower.
	tower = level.towers.get_child(0)
	tower_health = Component.get_health_component_or_die(tower)

func test_tower_destruction_fails_level():
	await wait_for_signal(level.level_failed, 3, "Waiting for level to fail")
	assert_signal_emitted(level, "level_failed")
