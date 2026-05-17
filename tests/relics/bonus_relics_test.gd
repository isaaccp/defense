extends GutTest

# Tests for the 4 starting bonus relics (one per class):
# Regeneration Ring (Warrior), Hallowed Vestments (Priest),
# Killer's Insight (Rogue), Arcane Battery (Wizard).

const basic_test_level_scene = preload("res://tests/actions/basic_test_level.tscn")
const test_character = preload("res://character/playable_characters/test_character.tres")
const ranged_attack = preload("res://game_logic/attack_types/ranged.tres")
const melee_attack = preload("res://game_logic/attack_types/melee.tres")
const slashing_damage_type = preload("res://game_logic/damage_types/slashing.tres")

func _make_character_with_relic(relic_name: StringName) -> Level:
	var level: Level = basic_test_level_scene.instantiate()
	var gc: GameplayCharacter = test_character.duplicate(true)
	gc.relics = [relic_name]
	level.initialize([gc])
	add_child_autoqfree(level)
	# VitalsComponent._initialize() runs deferred.
	await wait_frames(1)
	return level

func _actuator(actor: Node) -> EffectActuatorComponent:
	var a: EffectActuatorComponent = Component.get_or_die(actor, EffectActuatorComponent.component)
	a.run()  # loads relics from the GameplayCharacter
	return a

func _vitals(actor: Node) -> VitalsComponent:
	return Component.get_or_die(actor, VitalsComponent.component)

# --- Regeneration Ring (ATTRIBUTE: +1.0 health_regen) ---

func test_regeneration_ring_boosts_health_regen():
	var level: Level = await _make_character_with_relic(&"Regeneration Ring")
	var actor: Node = level.characters.get_child(0)
	var actuator: EffectActuatorComponent = _actuator(actor)
	var base: float = test_character.attributes.health_regen
	var modified: Attributes = actuator.modified_attributes(test_character.attributes)
	assert_eq(modified.health_regen, base + 1.0, "Health regen should be base +1.0/s")

# --- Hallowed Vestments (ATTRIBUTE: +50% resistance vs ranged) ---

func test_hallowed_vestments_adds_ranged_resistance():
	var level: Level = await _make_character_with_relic(&"Hallowed Vestments")
	var actor: Node = level.characters.get_child(0)
	var actuator: EffectActuatorComponent = _actuator(actor)
	var modified: Attributes = actuator.modified_attributes(test_character.attributes)
	# Ranged hit: 50% damage taken → multiplier 0.5
	var ranged_mult: float = modified.resistance_multiplier_for(ranged_attack, slashing_damage_type)
	assert_eq(ranged_mult, 0.5, "Ranged attacks should be halved")

func test_hallowed_vestments_does_not_affect_melee():
	var level: Level = await _make_character_with_relic(&"Hallowed Vestments")
	var actor: Node = level.characters.get_child(0)
	var actuator: EffectActuatorComponent = _actuator(actor)
	var modified: Attributes = actuator.modified_attributes(test_character.attributes)
	var melee_mult: float = modified.resistance_multiplier_for(melee_attack, slashing_damage_type)
	assert_eq(melee_mult, 1.0, "Melee attacks should be unaffected")

# --- Killer's Insight (HIT_EFFECT: +50% dmg vs target <30% HP) ---

func test_killers_insight_boosts_damage_against_wounded_target():
	var level: Level = await _make_character_with_relic(&"Killer's Insight")
	var actor: Node = level.characters.get_child(0)
	var actuator: EffectActuatorComponent = _actuator(actor)
	# Set up wounded enemy (test level has 1 enemy).
	var enemy: Node = level.enemies.get_child(0)
	var enemy_vitals: VitalsComponent = _vitals(enemy)
	var max_hp: float = enemy_vitals.get_vital_max(VitalsComponent.VitalType.HEALTH)
	# 20% HP → under the 30% threshold.
	enemy_vitals.test_set_vital_current(VitalsComponent.VitalType.HEALTH, max_hp * 0.20)
	var hit_effect = HitEffect.new()
	hit_effect.damage_type = slashing_damage_type
	hit_effect.damage_multiplier = 1.0
	var effect_log: Array[String] = []
	var effective: HitEffect = actuator.modified_hit_effect(hit_effect, enemy, effect_log)
	assert_eq(effective.damage_multiplier, 1.5, "Should multiply damage by 1.5 vs wounded target")
	assert_eq(effect_log.size(), 1, "Should log the application")

func test_killers_insight_no_op_against_healthy_target():
	var level: Level = await _make_character_with_relic(&"Killer's Insight")
	var actor: Node = level.characters.get_child(0)
	var actuator: EffectActuatorComponent = _actuator(actor)
	var enemy: Node = level.enemies.get_child(0)
	# Enemy starts at full HP by default.
	var hit_effect = HitEffect.new()
	hit_effect.damage_type = slashing_damage_type
	hit_effect.damage_multiplier = 1.0
	var effect_log: Array[String] = []
	var effective: HitEffect = actuator.modified_hit_effect(hit_effect, enemy, effect_log)
	assert_eq(effective.damage_multiplier, 1.0, "Should not modify damage vs healthy target")
	assert_eq(effect_log.size(), 0, "Should not log when no-op")

# --- Arcane Battery (ATTRIBUTE: +30 max focus) ---

func test_arcane_battery_raises_max_focus():
	var level: Level = await _make_character_with_relic(&"Arcane Battery")
	var actor: Node = level.characters.get_child(0)
	var actuator: EffectActuatorComponent = _actuator(actor)
	var base: int = test_character.attributes.focus
	var modified: Attributes = actuator.modified_attributes(test_character.attributes)
	assert_eq(modified.focus, base + 30, "Max focus should be base +30")
