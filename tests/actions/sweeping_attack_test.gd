extends GutTest

# Level has 1 enemy.
const empty_level_scene = preload("res://tests/actions/empty_level.tscn")
const test_character = preload("res://character/playable_characters/test_character.tres")
const sweeping_attack = preload("res://skill_tree/actions/sweeping_attack.tres")
const enemy_target = preload("res://skill_tree/targets/enemy.tres")

var level: Level
var character: Node2D
var character_behavior: BehaviorComponent
var enemy: Node2D
var enemy_health: HealthComponent

func make_sweeping_behavior() -> StoredBehavior:
	var behavior = StoredBehavior.new()
	behavior.stored_rules.append(
		TestUtils.rule_def(enemy_target, sweeping_attack)
	)
	return behavior

func before_each():
	level = empty_level_scene.instantiate()
	level.initialize([test_character])
	add_child_autoqfree(level)
	# Set up character.
	character = level.characters.get_child(0)
	character_behavior = character.get_component_or_die(BehaviorComponent)
	TestUtils.set_character_behavior(character, make_sweeping_behavior())

func test_sweeping_attack_one_enemy():
	var enemy = TestUtils.make_barrel(10)
	level.enemies.add_child(enemy)
	# Put the enemy close to the character.
	enemy.position = character.position + Vector2.RIGHT * 30
	enemy_health = enemy.get_component_or_die(HealthComponent)

	level.start()

	watch_signals(enemy_health)
	# Wait for one second.
	await wait_seconds(1.0)
	# There is an initial health update, so we expected that at this point
	# the enemy has had health updated twice.
	assert_signal_emit_count(enemy_health, "health_updated", 2)
	# For debugging.
	TestUtils.dump_all_emits(self, enemy_health, "health_updated")

func test_sweeping_attack_multiple_enemies():
	var offsets = [
		Vector2.RIGHT * 30,
		Vector2.UP * 20 + Vector2.RIGHT * 20,
		Vector2.DOWN * 20 + Vector2.RIGHT * 20
	]
	var health_components = []
	for i in range(3):
		var enemy = TestUtils.make_barrel(10)
		level.enemies.add_child(enemy)
		enemy.position = character.position + offsets[i]
		health_components.append(enemy.get_component_or_die(HealthComponent))

	level.start()

	for i in range(3):
		watch_signals(health_components[i])

	# Wait for one second.
	await wait_seconds(1.0)

	for i in range(3):
		# There is an initial health update, so we expected that at this point
		# all components have had health updated twice.
		assert_signal_emit_count(health_components[i], "health_updated", 2)
		# For debugging.
		TestUtils.dump_all_emits(self, health_components[i], "health_updated")
