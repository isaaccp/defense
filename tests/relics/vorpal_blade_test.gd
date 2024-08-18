extends GutTest

# Level has 1 enemy.
const basic_test_level_scene = preload("res://tests/actions/basic_test_level.tscn")
const test_character = preload("res://character/playable_characters/test_character.tres")
const sword_attack = preload("res://skill_tree/actions/sword_attack.tres")
const move_to = preload("res://skill_tree/actions/move_to.tres")
const enemy_target = preload("res://skill_tree/targets/enemy.tres")
const vorpal_blade = preload("res://effects/relics/vorpal_blade.tres")
const slashing_damage_type = preload("res://game_logic/damage_types/slashing.tres")

var level: Level
var character: Node2D
var enemy: Node2D

func make_sword_behavior() -> StoredBehavior:
	var behavior = StoredBehavior.new()
	behavior.stored_rules.append(
		TestUtils.rule_def(enemy_target, sword_attack)
	)
	return behavior

func before_each():
	level = basic_test_level_scene.instantiate()
	var vorpal_test_character = test_character.duplicate(true)
	vorpal_test_character.add_relic(vorpal_blade.name)
	level.initialize([vorpal_test_character])
	add_child_autoqfree(level)
	# Set up character.
	character = level.characters.get_child(0)
	# Set up enemy.
	enemy = level.enemies.get_child(0)
	enemy.get_component_or_die(BehaviorComponent).stored_behavior = StoredBehavior.new()

func test_effect_actuator():
	var effect_actuator: EffectActuatorComponent = character.get_component_or_die(EffectActuatorComponent)
	# Needed to load the relics from GameplayCharacter.
	effect_actuator.run()
	# Test that hit effect is modified as expected.
	var hit_effect = HitEffect.new()
	hit_effect.damage_type = slashing_damage_type
	hit_effect.flat_armor_pen = 1
	var effect_log: Array[String] = []
	var effective_hit_effect = effect_actuator.modified_hit_effect(hit_effect, effect_log)
	assert_eq(effective_hit_effect.flat_armor_pen, 2)
	assert_eq(effect_log.size(), 1)

func test_attack_in_level():
	TestUtils.set_character_behavior(character, make_sword_behavior())
	var enemy_health: HealthComponent = enemy.get_component_or_die(HealthComponent)
	enemy.position = character.position + Vector2.RIGHT * 40
	level.start()
	watch_signals(enemy_health)
	await wait_for_signal(enemy_health.hit, 3, "Waiting for health to report hit")
	var enemy_health_hit_params = get_signal_parameters(enemy_health, "hit", 0)
	var hit_effect: HitEffect = enemy_health_hit_params[0]
	assert_eq(hit_effect.flat_armor_pen, 1)  # Default for sword attack is 0, should be 1 now.
