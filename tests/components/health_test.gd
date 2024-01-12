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

func test_health_component():
	await wait_frames(2)
	assert_eq(health_component.max_health, max_health)

	var hit_effect = HitEffect.new()
	hit_effect.damage = 12

	watch_signals(health_component)
	watch_signals(logging_component)

	# Must return true as damage is happening.
	assert_eq(health_component.process_hit(hit_effect), true)
	assert_eq(health_component.health, 28)
	assert_eq(get_signal_emit_count(health_component, "health_updated"), 1)
	var params = get_signal_parameters(health_component, "health_updated")
	assert_not_null(params)
	var health_update = params[0] as HealthComponent.HealthUpdate
	assert_eq(health_update.max_health, 40)
	assert_eq(health_update.health, 28)
	assert_eq(health_update.prev_health, 40)
	assert_eq(health_update.is_heal, false)

	# Check armor effect.
	attributes_component.base_attributes.armor = 2
	# Still true as damage gets through.
	assert_eq(health_component.process_hit(hit_effect), true)
	assert_eq(health_component.health, 18)
	assert_eq(get_signal_emit_count(health_component, "health_updated"), 2)
	params = get_signal_parameters(health_component, "health_updated")
	assert_not_null(params)
	health_update = params[0] as HealthComponent.HealthUpdate
	# Only 10 damage, due to armor.
	assert_eq(health_update.health, 18)
	assert_eq(health_update.prev_health, 28)

	# Check armor >= damage.
	hit_effect.damage = 2
	# Should return false as no damage gets through.
	assert_eq(health_component.process_hit(hit_effect), false)
	# No change.
	assert_eq(health_component.health, 18)
	# No new update.
	assert_eq(get_signal_emit_count(health_component, "health_updated"), 2)

	# Check death.
	hit_effect.damage = 20
	assert_eq(health_component.process_hit(hit_effect), true)
	assert_eq(health_component.health, 0)
	assert_true(health_component.is_dead)
	assert_eq(get_signal_emit_count(health_component, "health_updated"), 3)
	assert_eq(get_signal_emit_count(health_component, "died"), 1)

	# Don't want to add explicit tests for logging messages as they
	# would depend on format, but dumping them here makes it super easy
	# to see if something went wrong and quickly fix it.
	TestUtils.dump_all_emits(self, logging_component, "log_entry_added")
