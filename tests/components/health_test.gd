extends GutTest

const attributes_component_scene = preload("res://components/attributes_component.tscn")
const health_component_scene = preload("res://components/health_component.tscn")
const logging_component_scene = preload("res://components/logging_component.tscn")

var health_component: HealthComponent
var attributes_component: AttributesComponent
var logging_component: LoggingComponent

const max_health = 40

func before_each():
	attributes_component = attributes_component_scene.instantiate()
	attributes_component.base_attributes = Attributes.new()
	attributes_component.base_attributes.health = max_health
	logging_component = logging_component_scene.instantiate()
	health_component = health_component_scene.instantiate()
	health_component.attributes_component = attributes_component
	health_component.logging_component = logging_component
	add_child_autoqfree(attributes_component)
	add_child_autoqfree(logging_component)
	add_child_autoqfree(health_component)

	await wait_frames(2)

	watch_signals(health_component)
	watch_signals(logging_component)

func test_initial_health():
	assert_eq(health_component.max_health, max_health)

func test_hit_no_armor():
	var hit_effect = HitEffect.new()
	hit_effect.damage = 12
	hit_effect.damage_type = preload("res://game_logic/damage_types/slashing.tres")

	# Must return true as damage is happening.
	assert_eq(health_component.process_hit(hit_effect), true)
	assert_eq(health_component.health, max_health - 12)
	assert_signal_emitted(health_component, "health_updated")
	var params = get_signal_parameters(health_component, "health_updated")
	assert_not_null(params)
	var health_update = params[0] as HealthComponent.HealthUpdate
	assert_eq(health_update.max_health, max_health)
	assert_eq(health_update.health, max_health - 12)
	assert_eq(health_update.prev_health, max_health)
	assert_eq(health_update.is_heal, false)
	TestUtils.dump_all_emits(self, logging_component, "log_entry_added")

func test_physical_hit_armor_damage():
	var hit_effect = HitEffect.new()
	hit_effect.damage = 12
	hit_effect.damage_type = preload("res://game_logic/damage_types/slashing.tres")

	# Check armor effect.
	attributes_component.base_attributes.armor = 2
	# Still true as damage gets through.
	assert_eq(health_component.process_hit(hit_effect), true)
	assert_eq(health_component.health, max_health - 10)
	assert_signal_emitted(health_component, "health_updated")
	var params = get_signal_parameters(health_component, "health_updated")
	assert_not_null(params)
	var health_update = params[0] as HealthComponent.HealthUpdate
	# Only 10 damage, due to armor.
	assert_eq(health_update.health, max_health - 10)
	assert_eq(health_update.prev_health, max_health)
	TestUtils.dump_all_emits(self, logging_component, "log_entry_added")

func test_physical_hit_armor_no_damage():
	var hit_effect = HitEffect.new()
	# Check armor >= damage.
	hit_effect.damage = 2
	hit_effect.damage_type = preload("res://game_logic/damage_types/slashing.tres")

	# Same armor as damage.
	attributes_component.base_attributes.armor = 2

	# Should return false as no damage gets through.
	assert_eq(health_component.process_hit(hit_effect), false)
	# No change.
	assert_eq(health_component.health, max_health)
	assert_signal_not_emitted(health_component, "health_updated")
	TestUtils.dump_all_emits(self, logging_component, "log_entry_added")

func test_non_physical_hit_ignores_armor():
	var hit_effect = HitEffect.new()
	hit_effect.damage = 2
	# Check non-physical damage ignores armor.death.
	hit_effect.damage_type = preload("res://game_logic/damage_types/arcane.tres")
	# True as damage gets through now.
	assert_eq(health_component.process_hit(hit_effect), true)
	assert_eq(health_component.health, max_health - 2)
	assert_signal_emitted(health_component, "health_updated")
	var params = get_signal_parameters(health_component, "health_updated")
	assert_not_null(params)
	var health_update = params[0] as HealthComponent.HealthUpdate
	# 2 damage, ignoring armor.
	assert_eq(health_update.health, max_health - 2)
	assert_eq(health_update.prev_health, max_health)
	TestUtils.dump_all_emits(self, logging_component, "log_entry_added")

func test_resistance_plus_armor():
	var hit_effect = HitEffect.new()
	hit_effect.damage = 20
	hit_effect.damage_type = preload("res://game_logic/damage_types/slashing.tres")
	attributes_component.base_attributes.armor = 4
	var resistance = Resistance.new()
	resistance.damage_type = hit_effect.damage_type
	resistance.percentage = 50
	attributes_component.base_attributes.resistance.append(resistance)

	# True as damage gets through.
	assert_eq(health_component.process_hit(hit_effect), true)
	var expected_damage = (20 - 4) / 2
	assert_eq(health_component.health, max_health - expected_damage)
	assert_signal_emitted(health_component, "health_updated")
	var params = get_signal_parameters(health_component, "health_updated")
	assert_not_null(params)
	var health_update = params[0] as HealthComponent.HealthUpdate
	assert_eq(health_update.health, max_health - expected_damage)
	assert_eq(health_update.prev_health, max_health)
	TestUtils.dump_all_emits(self, logging_component, "log_entry_added")

func test_vulnerability():
	var hit_effect = HitEffect.new()
	hit_effect.damage = 10
	hit_effect.damage_type = preload("res://game_logic/damage_types/slashing.tres")
	var resistance = Resistance.new()
	resistance.damage_type = hit_effect.damage_type
	resistance.percentage = -100
	attributes_component.base_attributes.resistance.append(resistance)

	# True as damage gets through.
	assert_eq(health_component.process_hit(hit_effect), true)
	var expected_damage = 10 * 2
	assert_eq(health_component.health, max_health - expected_damage)
	assert_signal_emitted(health_component, "health_updated")
	var params = get_signal_parameters(health_component, "health_updated")
	assert_not_null(params)
	var health_update = params[0] as HealthComponent.HealthUpdate
	assert_eq(health_update.health, max_health - expected_damage)
	assert_eq(health_update.prev_health, max_health)
	TestUtils.dump_all_emits(self, logging_component, "log_entry_added")

func test_heal():
	health_component.health = 20
	var hit_effect = HitEffect.new()
	hit_effect.damage = -10

	attributes_component.base_attributes.armor = 5
	# Return true for heal.
	assert_eq(health_component.process_hit(hit_effect), true)
	assert_eq(health_component.health, 20 + 10)
	assert_signal_emitted(health_component, "health_updated")
	var params = get_signal_parameters(health_component, "health_updated")
	assert_not_null(params)
	var health_update = params[0] as HealthComponent.HealthUpdate
	assert_eq(health_update.health, 20 + 10)
	assert_eq(health_update.prev_health, 20)
	assert_true(health_update.is_heal)
	TestUtils.dump_all_emits(self, logging_component, "log_entry_added")

func test_death():
	var hit_effect = HitEffect.new()
	hit_effect.damage = max_health
	hit_effect.damage_type = preload("res://game_logic/damage_types/slashing.tres")

	watch_signals(health_component)
	watch_signals(logging_component)

	# Check death.
	assert_eq(health_component.process_hit(hit_effect), true)
	assert_eq(health_component.health, 0)
	assert_true(health_component.is_dead)
	assert_signal_emitted(health_component, "health_updated")
	assert_signal_emitted(health_component, "died")

	TestUtils.dump_all_emits(self, logging_component, "log_entry_added")
