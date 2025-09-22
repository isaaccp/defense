extends GutTest

const attributes_component_scene = preload("res://components/attributes_component.tscn")
const damage_component_scene = preload("res://components/damage_component.tscn")
const vitals_component_scene = preload("res://components/vitals_component.tscn")
const logging_component_scene = preload("res://components/logging_component.tscn")
const death_handler_component_scene = preload("res://components/death_handler_component.tscn")

var unit: Unit
var vitals_component: VitalsComponent
var attributes_component: AttributesComponent
var logging_component: LoggingComponent
var damage_component: DamageComponent
var death_handler_component: DeathHandlerComponent

const max_health = 40

func before_each():
	unit = Unit.new()
	attributes_component = attributes_component_scene.instantiate()
	attributes_component.name = "AttributesComponent"
	attributes_component.base_attributes = Attributes.new()
	attributes_component.base_attributes.health = max_health
	logging_component = logging_component_scene.instantiate()
	logging_component.name = "LoggingComponent"
	vitals_component = vitals_component_scene.instantiate()
	vitals_component.name = "VitalsComponent"
	vitals_component.attributes_component = attributes_component
	vitals_component.logging_component = logging_component
	damage_component = damage_component_scene.instantiate()
	damage_component.name = "DamageComponent"
	damage_component.vitals_component = vitals_component
	damage_component.attributes_component = attributes_component
	death_handler_component = death_handler_component_scene.instantiate()
	death_handler_component.name = "DeathHandlerComponent"
	death_handler_component.vitals_component = vitals_component
	unit.add_child(attributes_component)
	unit.add_child(logging_component)
	unit.add_child(vitals_component)
	unit.add_child(damage_component)
	unit.add_child(death_handler_component)
	add_child_autoqfree(unit)
	
	damage_component.run()

	await wait_frames(2)

	watch_signals(vitals_component)
	watch_signals(logging_component)
	watch_signals(damage_component)

func test_initial_health():
	var vitals_max_health = vitals_component.get_vital_max(VitalsComponent.VitalType.HEALTH)
	assert_eq(vitals_max_health, max_health)

func test_hit_no_armor():
	var hit_effect = HitEffect.new()
	hit_effect.damage = 12
	hit_effect.damage_type = preload("res://game_logic/damage_types/slashing.tres")

	# Must return true as damage is happening.
	var hit_result = damage_component.process_hit(hit_effect)
	assert_eq(hit_result.damage, 12)
	TestUtils.dump_all_emits(self, logging_component, "log_entry_added")
	assert_eq(vitals_component.get_vital_current(VitalsComponent.VitalType.HEALTH), max_health - 12)
	assert_signal_emitted(vitals_component, "vital_updated")
	var params = get_signal_parameters(vitals_component, "vital_updated")
	assert_not_null(params)
	var vital_update = params[0] as VitalsComponent.VitalUpdate
	assert_eq(vital_update.max_value, max_health)
	assert_eq(vital_update.current_value, max_health - 12)
	assert_eq(vital_update.prev_value, max_health)
	assert_eq(vital_update.is_increase, false)

func test_physical_hit_armor_damage():
	var hit_effect = HitEffect.new()
	hit_effect.damage = 12
	hit_effect.damage_type = preload("res://game_logic/damage_types/slashing.tres")

	# Check armor effect.
	attributes_component.base_attributes.armor = 2
	# Still true as damage gets through.
	var hit_result = damage_component.process_hit(hit_effect)
	assert_eq(hit_result.damage, 10)
	assert_eq(vitals_component.get_vital_current(VitalsComponent.VitalType.HEALTH), max_health - 10)
	assert_signal_emitted(vitals_component, "vital_updated")
	var params = get_signal_parameters(vitals_component, "vital_updated")
	assert_not_null(params)
	var vital_update = params[0] as VitalsComponent.VitalUpdate
	# Only 10 damage, due to armor.
	assert_eq(vital_update.current_value, max_health - 10)
	assert_eq(vital_update.prev_value, max_health)
	TestUtils.dump_all_emits(self, logging_component, "log_entry_added")

func test_physical_hit_armor_no_damage():
	var hit_effect = HitEffect.new()
	# Check armor >= damage.
	hit_effect.damage = 2
	hit_effect.damage_type = preload("res://game_logic/damage_types/slashing.tres")

	# Same armor as damage.
	attributes_component.base_attributes.armor = 2

	# Should return false as no damage gets through.
	var hit_result = damage_component.process_hit(hit_effect)
	assert_eq(hit_result.damage, 0)
	# No change.
	assert_eq(vitals_component.get_vital_current(VitalsComponent.VitalType.HEALTH), max_health)
	assert_signal_not_emitted(vitals_component, "vital_updated")
	TestUtils.dump_all_emits(self, logging_component, "log_entry_added")

func test_physical_hit_flat_armor_pen():
	var hit_effect = HitEffect.new()
	hit_effect.damage = 2
	hit_effect.flat_armor_pen = 1
	attributes_component.base_attributes.armor = 2
	# damage - (armor - flat_armor_pen)
	var expected_damage = 1
	hit_effect.damage_type = preload("res://game_logic/damage_types/slashing.tres")
	var hit_result = damage_component.process_hit(hit_effect)
	assert_eq(hit_result.damage, expected_damage)
	assert_eq(vitals_component.get_vital_current(VitalsComponent.VitalType.HEALTH), max_health - expected_damage)
	assert_signal_emitted(vitals_component, "vital_updated")
	var params = get_signal_parameters(vitals_component, "vital_updated")
	assert_not_null(params)
	var vital_update = params[0] as VitalsComponent.VitalUpdate
	# 1 damage, due to armor penetration.
	assert_eq(vital_update.current_value, max_health - expected_damage)
	assert_eq(vital_update.prev_value, max_health)
	TestUtils.dump_all_emits(self, logging_component, "log_entry_added")

func test_physical_hit_fraction_armor_pen():
	var hit_effect = HitEffect.new()
	hit_effect.damage = 2
	hit_effect.fraction_armor_pen = 0.5
	attributes_component.base_attributes.armor = 2
	# damage - (armor - armor * fraction_armor_pen)
	var expected_damage = 1
	hit_effect.damage_type = preload("res://game_logic/damage_types/slashing.tres")
	var hit_result = damage_component.process_hit(hit_effect)
	assert_eq(hit_result.damage, expected_damage)
	assert_eq(vitals_component.get_vital_current(VitalsComponent.VitalType.HEALTH), max_health - expected_damage)
	assert_signal_emitted(vitals_component, "vital_updated")
	var params = get_signal_parameters(vitals_component, "vital_updated")
	assert_not_null(params)
	var vital_update = params[0] as VitalsComponent.VitalUpdate
	# 1 damage, due to armor penetration.
	assert_eq(vital_update.current_value, max_health - expected_damage)
	assert_eq(vital_update.prev_value, max_health)
	TestUtils.dump_all_emits(self, logging_component, "log_entry_added")

func test_physical_hit_both_armor_pen():
	var hit_effect = HitEffect.new()
	hit_effect.damage = 2
	hit_effect.fraction_armor_pen = 0.5
	hit_effect.flat_armor_pen = 1
	attributes_component.base_attributes.armor = 2
	# damage - (armor - (armor * fraction_armor_pen + flat_armor_pen)
	var expected_damage = 2
	hit_effect.damage_type = preload("res://game_logic/damage_types/slashing.tres")
	var hit_result = damage_component.process_hit(hit_effect)
	assert_eq(hit_result.damage, expected_damage)
	assert_eq(hit_result.damage, expected_damage)
	assert_eq(vitals_component.get_vital_current(VitalsComponent.VitalType.HEALTH), max_health - expected_damage)
	assert_signal_emitted(vitals_component, "vital_updated")
	var params = get_signal_parameters(vitals_component, "vital_updated")
	assert_not_null(params)
	var vital_update = params[0] as VitalsComponent.VitalUpdate
	# 1 damage, due to armor penetration.
	assert_eq(vital_update.current_value, max_health - expected_damage)
	assert_eq(vital_update.prev_value, max_health)
	TestUtils.dump_all_emits(self, logging_component, "log_entry_added")

func test_non_physical_hit_ignores_armor():
	var hit_effect = HitEffect.new()
	hit_effect.damage = 2
	# Check non-physical damage ignores armor.death.
	hit_effect.damage_type = preload("res://game_logic/damage_types/arcane.tres")
	# Same armor as damage.
	attributes_component.base_attributes.armor = 2
	var hit_result = damage_component.process_hit(hit_effect)
	assert_eq(hit_result.damage, 2)
	assert_eq(vitals_component.get_vital_current(VitalsComponent.VitalType.HEALTH), max_health - 2)
	assert_signal_emitted(vitals_component, "vital_updated")
	var params = get_signal_parameters(vitals_component, "vital_updated")
	assert_not_null(params)
	var vital_update = params[0] as VitalsComponent.VitalUpdate
	# 1 damage, due to armor penetration.
	assert_eq(vital_update.current_value, max_health - 2)
	assert_eq(vital_update.prev_value, max_health)
	TestUtils.dump_all_emits(self, logging_component, "log_entry_added")

func test_resistance_plus_armor():
	var hit_effect = HitEffect.new()
	hit_effect.damage = 20
	hit_effect.attack_type = preload("res://game_logic/attack_types/melee.tres")
	hit_effect.damage_type = preload("res://game_logic/damage_types/slashing.tres")
	attributes_component.base_attributes.armor = 4
	var resistance = Resistance.new()
	resistance.damage_type = hit_effect.damage_type
	resistance.percentage = 50
	attributes_component.base_attributes.resistance.append(resistance)

	# True as damage gets through.
	var hit_result = damage_component.process_hit(hit_effect)
	var expected_damage = (20 - 4) / 2
	assert_eq(hit_result.damage, expected_damage)
	assert_eq(vitals_component.get_vital_current(VitalsComponent.VitalType.HEALTH), max_health - expected_damage)
	assert_signal_emitted(vitals_component, "vital_updated")
	var params = get_signal_parameters(vitals_component, "vital_updated")
	assert_not_null(params)
	var vital_update = params[0] as VitalsComponent.VitalUpdate
	# 1 damage, due to armor penetration.
	assert_eq(vital_update.current_value, max_health - expected_damage)
	assert_eq(vital_update.prev_value, max_health)
	TestUtils.dump_all_emits(self, logging_component, "log_entry_added")

func test_vulnerability():
	var hit_effect = HitEffect.new()
	hit_effect.damage = 10
	hit_effect.attack_type = preload("res://game_logic/attack_types/melee.tres")
	hit_effect.damage_type = preload("res://game_logic/damage_types/slashing.tres")
	var resistance = Resistance.new()
	resistance.damage_type = hit_effect.damage_type
	resistance.percentage = -100
	attributes_component.base_attributes.resistance.append(resistance)

	# True as damage gets through.
	var hit_result = damage_component.process_hit(hit_effect)
	var expected_damage = 10 * 2
	assert_eq(hit_result.damage, expected_damage)
	assert_eq(vitals_component.get_vital_current(VitalsComponent.VitalType.HEALTH), max_health - expected_damage)
	assert_signal_emitted(vitals_component, "vital_updated")
	var params = get_signal_parameters(vitals_component, "vital_updated")
	assert_not_null(params)
	var vital_update = params[0] as VitalsComponent.VitalUpdate
	assert_eq(vital_update.current_value, max_health - expected_damage)
	assert_eq(vital_update.prev_value, max_health)
	TestUtils.dump_all_emits(self, logging_component, "log_entry_added")

func test_heal():
	vitals_component.test_set_vital_current(VitalsComponent.VitalType.HEALTH, 20)
	var hit_effect = HitEffect.new()
	hit_effect.damage = -10

	attributes_component.base_attributes.armor = 5

	var hit_result = damage_component.process_hit(hit_effect)
	assert_eq(hit_result.damage, -10)
	assert_eq(vitals_component.get_vital_current(VitalsComponent.VitalType.HEALTH), 20 + 10)
	assert_signal_emitted(vitals_component, "vital_updated")
	var params = get_signal_parameters(vitals_component, "vital_updated")
	assert_not_null(params)
	var vital_update = params[0] as VitalsComponent.VitalUpdate
	assert_eq(vital_update.type, VitalsComponent.VitalType.HEALTH)
	assert_eq(vital_update.current_value, 20 + 10)
	assert_eq(vital_update.prev_value, 20)
	assert_true(vital_update.is_increase)
	TestUtils.dump_all_emits(self, logging_component, "log_entry_added")

func test_health_depleted():
	var hit_effect = HitEffect.new()
	hit_effect.damage = max_health
	hit_effect.damage_type = preload("res://game_logic/damage_types/slashing.tres")

	# Check death.
	var hit_result = damage_component.process_hit(hit_effect)
	assert_eq(hit_result.damage, max_health)
	assert_eq(vitals_component.get_vital_current(VitalsComponent.VitalType.HEALTH), 0)
	assert_signal_emitted(vitals_component, "vital_depleted")

	TestUtils.dump_all_emits(self, logging_component, "log_entry_added")
