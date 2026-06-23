extends GutTest

const status_component_scene = preload("res://components/status_component.tscn")
const effect_actuator_component_scene = preload("res://components/effect_actuator_component.tscn")
const attributes_component_scene = preload("res://components/attributes_component.tscn")
const vitals_component_scene = preload("res://components/vitals_component.tscn")
const damage_component_scene = preload("res://components/damage_component.tscn")

var unit: Node
var status_component: StatusComponent
var effect_actuator_component: EffectActuatorComponent
var attributes_component: AttributesComponent
var vitals_component: VitalsComponent
var damage_component: DamageComponent

func before_each():
	var unit_script = GDScript.new()
	unit_script.source_code = "extends Node\nvar config\nvar destroyed = false"
	unit_script.reload()
	unit = Node.new()
	unit.set_script(unit_script)
	
	status_component = status_component_scene.instantiate()
	status_component.name = "StatusComponent"
	
	attributes_component = attributes_component_scene.instantiate()
	attributes_component.name = "AttributesComponent"
	attributes_component.base_attributes = Attributes.new()
	attributes_component.base_attributes.health = 100
	attributes_component.base_attributes.speed = 100
	
	vitals_component = vitals_component_scene.instantiate()
	vitals_component.name = "VitalsComponent"
	vitals_component.attributes_component = attributes_component
	
	damage_component = damage_component_scene.instantiate()
	damage_component.name = "DamageComponent"
	damage_component.vitals_component = vitals_component
	damage_component.attributes_component = attributes_component
	
	effect_actuator_component = effect_actuator_component_scene.instantiate()
	effect_actuator_component.name = "EffectActuatorComponent"
	effect_actuator_component.status_component = status_component
	
	attributes_component.effect_actuator_component = effect_actuator_component
	damage_component.effect_actuator_component = effect_actuator_component
	
	unit.add_child(attributes_component)
	unit.add_child(vitals_component)
	unit.add_child(damage_component)
	unit.add_child(status_component)
	unit.add_child(effect_actuator_component)
	
	add_child_autoqfree(unit)
	
	vitals_component._initialize()
	vitals_component.run()
	damage_component.run()
	effect_actuator_component.run()

func test_poisoned_status():
	vitals_component.test_set_vital_current(VitalsComponent.VitalType.HEALTH, 100)
	
	var poisoned_def = preload("res://effects/statuses/poisoned.tres")
	
	var params = PoisonedParams.new()
	params.tick_rate = 1.0
	params.damage_per_tick = 5
	
	status_component.set_status(&"Poison Dart", poisoned_def, params, 5.0)
	
	effect_actuator_component._process(0.5)
	assert_eq(int(vitals_component.get_vital_current(VitalsComponent.VitalType.HEALTH)), 100)
	
	effect_actuator_component._process(0.5)
	assert_eq(int(vitals_component.get_vital_current(VitalsComponent.VitalType.HEALTH)), 95)
	
	effect_actuator_component._process(2.0)
	assert_eq(int(vitals_component.get_vital_current(VitalsComponent.VitalType.HEALTH)), 85)

func test_hasted_status():
	var hasted_def = preload("res://effects/statuses/hasted.tres")
	
	var params = HastedParams.new()
	params.action_speed_multiplier = 1.5
	params.speed_multiplier = 1.2
	
	status_component.set_status(&"Blessing", hasted_def, params, 5.0)
	
	var mod_attrs = effect_actuator_component.modified_attributes(attributes_component.base_attributes)
	
	assert_eq(mod_attrs.speed, 120.0, "Speed should be increased by 20%")
	
	var dummy_action = ActionDef.new()
	var log_arr: Array[String] = []
	var mod_cooldown = effect_actuator_component.modified_cooldown(dummy_action, 10.0, log_arr)
	assert_eq(mod_cooldown, 10.0 / 1.5, "Cooldown should be divided by action_speed modifier")

func test_fortified_status():
	var fortified_def = preload("res://effects/statuses/fortified.tres")
	
	var params = FortifiedParams.new()
	params.damage_multiplier = 0.7 # 30% reduction (70% damage taken)
	
	status_component.set_status(&"Shield Wall", fortified_def, params, 5.0)
	
	var hit = HitEffect.new()
	hit.damage = 100
	hit.damage_type = preload("res://game_logic/damage_types/slashing.tres")
	
	var log_arr: Array[String] = []
	var mod_hit = effect_actuator_component.modified_incoming_hit_effect(hit, log_arr)
	
	assert_eq(int(mod_hit.adjusted_damage()), 70, "Incoming damage should be reduced by 30%")


func test_high_focus_status():
	attributes_component.base_attributes.focus_regen = 10.0
	attributes_component._on_attribute_effects_changed()
	
	var high_focus_def = preload("res://effects/statuses/high_focus.tres")
	
	var params = HighFocusParams.new()
	params.focus_regen_multiplier = 2.5
	
	status_component.set_status(&"Skill", high_focus_def, params, 5.0)
	
	var mod_attrs = effect_actuator_component.modified_attributes(attributes_component.base_attributes)
	assert_eq(mod_attrs.focus_regen, 25.0, "Focus regen should be multiplied by 2.5")

func test_magic_armor_status():
	attributes_component.base_attributes.armor = 5
	attributes_component._on_attribute_effects_changed()
	
	var magic_armor_def = preload("res://effects/statuses/magic_armor.tres")
	
	var params = MagicArmorParams.new()
	params.armor_bonus = 10
	
	status_component.set_status(&"Skill", magic_armor_def, params, 5.0)
	
	var mod_attrs = effect_actuator_component.modified_attributes(attributes_component.base_attributes)
	assert_eq(mod_attrs.armor, 15, "Armor should be increased by 10")

func test_paralyzed_status():
	var paralyzed_def = preload("res://effects/statuses/paralyzed.tres")
	
	# Paralyzed has no params
	status_component.set_status(&"Skill", paralyzed_def, null, 5.0)
	
	assert_eq(effect_actuator_component.unable_to_act_count, 1, "Should be unable to act")
	
	status_component.remove_status(&"Skill", &"Paralyzed")
	
	assert_eq(effect_actuator_component.unable_to_act_count, 0, "Should be able to act again")

func test_projectile_ward_status():
	var projectile_ward_def = preload("res://effects/statuses/projectile_ward.tres")
	
	var params = ProjectileWardParams.new()
	params.ranged_attack_resistance = 50 # 50% resistance
	
	status_component.set_status(&"Skill", projectile_ward_def, params, 5.0)
	
	var mod_attrs = effect_actuator_component.modified_attributes(attributes_component.base_attributes)
	
	# Verify that resistance was added
	var has_ranged_res = false
	var ranged_attack = preload("res://game_logic/attack_types/ranged.tres")
	for res in mod_attrs.resistance:
		if res.attack_type == ranged_attack and res.percentage == 50:
			has_ranged_res = true
	assert_true(has_ranged_res, "Should have 50% ranged resistance")

func test_slowed_status():
	attributes_component.base_attributes.speed = 100.0
	attributes_component._on_attribute_effects_changed()
	
	var slowed_def = preload("res://effects/statuses/slowed.tres")
	
	# Slowed has hardcoded multiplier of 0.5
	status_component.set_status(&"Skill", slowed_def, null, 5.0)
	
	var mod_attrs = effect_actuator_component.modified_attributes(attributes_component.base_attributes)
	assert_eq(mod_attrs.speed, 50.0, "Speed should be halved")

func test_strength_surge_status():
	attributes_component.base_attributes.damage_multiplier = 1.0
	attributes_component._on_attribute_effects_changed()
	
	var strength_surge_def = preload("res://effects/statuses/strength_surge.tres")
	
	var params = StrengthSurgeParams.new()
	params.damage_multiplier = 1.5
	
	status_component.set_status(&"Skill", strength_surge_def, params, 5.0)
	
	var mod_attrs = effect_actuator_component.modified_attributes(attributes_component.base_attributes)
	assert_eq(mod_attrs.damage_multiplier, 1.5, "Damage multiplier should be 1.5")

func test_swiftness_status():
	attributes_component.base_attributes.speed = 100.0
	attributes_component._on_attribute_effects_changed()
	
	var swiftness_def = preload("res://effects/statuses/swiftness.tres")
	
	var params = SwiftnessParams.new()
	params.speed_multiplier = 1.4
	
	status_component.set_status(&"Skill", swiftness_def, params, 5.0)
	
	var mod_attrs = effect_actuator_component.modified_attributes(attributes_component.base_attributes)
	assert_eq(mod_attrs.speed, 140.0, "Speed should be multiplied by 1.4")
