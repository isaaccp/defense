extends GutTest

# Level has 1 enemy.
const empty_level_scene = preload("res://tests/actions/empty_level.tscn")
const test_character = preload("res://character/playable_characters/test_character.tres")
const seeking_bolt = preload("res://skill_tree/actions/seeking_bolt.tres")
const enemy_target = preload("res://skill_tree/targets/enemy.tres")
const farthest_first = preload("res://skill_tree/target_sorts/farthest_first.tres")
const once = preload("res://skill_tree/conditions/once.tres")

var level: Level
var character: Node2D

func make_seeking_bolt_behavior() -> StoredBehavior:
	var behavior = StoredBehavior.new()
	var farthest_enemy_target = enemy_target.duplicate(true)
	farthest_enemy_target.params.sort = StoredSkill.from_skill(farthest_first)
	behavior.stored_rules.append(
		TestUtils.rule_def(farthest_enemy_target, seeking_bolt, once)
	)
	return behavior

func before_each():
	level = empty_level_scene.instantiate()
	level.initialize([test_character])
	add_child_autoqfree(level)
	# Set up character.
	character = level.characters.get_child(0)

func test_seeking_bolt_with_one_actor():
	TestUtils.set_character_behavior(character, make_seeking_bolt_behavior())

	var target = TestUtils.make_barrel(5)
	level.enemies.add_child(target)
	target.position = character.position + 200 * Vector2.RIGHT
	var target_health = target.get_component_or_die(HealthComponent)

	level.start()

	await wait_for_signal(target_health.died, 3, "Waiting for enemy to die")
	assert_signal_emitted(target_health, "died")

func test_seeking_bolt_through_other_actor():
	TestUtils.set_character_behavior(character, make_seeking_bolt_behavior())

	var target = TestUtils.make_barrel(5)
	level.enemies.add_child(target)
	target.position = character.position + 200 * Vector2.RIGHT
	var target_health = target.get_component_or_die(HealthComponent)

	var obstacle = TestUtils.make_barrel(5)
	level.enemies.add_child(obstacle)
	obstacle.position = character.position + 100 * Vector2.RIGHT
	var obstacle_health = obstacle.get_component_or_die(HealthComponent)

	level.start()

	watch_signals(obstacle_health)
	await wait_for_signal(target_health.died, 3, "Waiting for enemy to die")
	assert_signal_emitted(target_health, "died")
	assert_signal_not_emitted(obstacle_health, "died")

func test_seeking_bolt_target_disappears():
	TestUtils.set_character_behavior(character, make_seeking_bolt_behavior())

	var character_behavior = character.get_component_or_die(BehaviorComponent) as BehaviorComponent

	var target = TestUtils.make_barrel(5)
	level.enemies.add_child(target)
	target.position = character.position + 250 * Vector2.RIGHT
	var target_health = target.get_component_or_die(HealthComponent)

	level.start()

	watch_signals(character_behavior)
	# Prepare time for seeking bolt is 0.5, after this time it should be spawned.
	await wait_seconds(0.6)
	# Check that there is a single seeking orb.
	assert_eq(character_behavior.action_sprites.get_child_count(), 1)

	# Simulate target dying.
	var hit_effect = HitEffect.new()
	hit_effect.attack_type = preload("res://game_logic/attack_types/melee.tres")
	hit_effect.damage_type = preload("res://game_logic/damage_types/slashing.tres")
	hit_effect.damage = 5
	target_health.process_hit(hit_effect)

	await wait_seconds(0.2, "Waiting to ensure seeking bolt disappears without issues")

	# At this time the seeking orb should have disappeared.
	assert_eq(character_behavior.action_sprites.get_child_count(), 0)
