extends GutTest

const status_component_scene = preload("res://components/status_component.tscn")
const effect_actuator_component_scene = preload("res://components/effect_actuator_component.tscn")

var unit: Node
var status_component: StatusComponent
var effect_actuator_component: EffectActuatorComponent

func before_each():
	unit = Node.new()
	status_component = status_component_scene.instantiate()
	status_component.name = "StatusComponent"
	effect_actuator_component = effect_actuator_component_scene.instantiate()
	effect_actuator_component.name = "EffectActuatorComponent"
	effect_actuator_component.status_component = status_component
	
	unit.add_child(status_component)
	unit.add_child(effect_actuator_component)
	add_child_autoqfree(unit)
	
	effect_actuator_component.run()

func test_status_duration_modifier():
	var mock_relic_script = GDScript.new()
	mock_relic_script.source_code = """
extends Effect
func modified_incoming_status_duration(status_def: StatusDef, duration: float) -> float:
	if status_def.status_type == StatusDef.StatusType.WARD:
		return duration * 2.0
	return duration
"""
	mock_relic_script.reload()
	
	var mock_relic_def = RelicDef.new()
	mock_relic_def.name = &"Mock Relic"
	var mock_types: Array[int] = [EffectDef.EffectType.MODIFIED_INCOMING_STATUS_DURATION]
	mock_relic_def.effect_types = mock_types
	mock_relic_def.effect_script = mock_relic_script
	
	effect_actuator_component.add_relic(mock_relic_def)
	
	var dummy_script = GDScript.new()
	dummy_script.source_code = "extends Effect"
	dummy_script.reload()
	
	var ward_status = StatusDef.new()
	ward_status.name = &"Mock Ward"
	ward_status.status_type = StatusDef.StatusType.WARD
	ward_status.effect_script = dummy_script
	
	var buff_status = StatusDef.new()
	buff_status.name = &"Mock Buff"
	buff_status.status_type = StatusDef.StatusType.BUFF
	buff_status.effect_script = dummy_script
	
	# Apply both with duration 5.0
	status_component.set_status(&"Some Action", ward_status, null, 5.0)
	status_component.set_status(&"Some Action", buff_status, null, 5.0)
	
	var ward_key = status_component._key(&"Some Action", ward_status.name)
	var buff_key = status_component._key(&"Some Action", buff_status.name)
	
	# Statuses keep elapsed_time relative expiration. So expiration_time = elapsed_time + duration
	assert_eq(status_component.status_metadata[buff_key].expiration_time, 5.0, "Buff duration should be unmodified")
	assert_eq(status_component.status_metadata[ward_key].expiration_time, 10.0, "Ward duration should be doubled")

func test_modified_attributes():
	var mock_relic_script = GDScript.new()
	mock_relic_script.source_code = """
extends Effect
func modify_attributes(attributes: Attributes) -> void:
	attributes.health += 10
"""
	mock_relic_script.reload()
	
	var mock_relic_def = RelicDef.new()
	mock_relic_def.name = &"Health Buff Relic"
	var mock_types: Array[int] = [EffectDef.EffectType.ATTRIBUTE]
	mock_relic_def.effect_types = mock_types
	mock_relic_def.effect_script = mock_relic_script
	
	effect_actuator_component.add_relic(mock_relic_def)
	
	var base_attributes = Attributes.new()
	base_attributes.health = 20
	var final_attributes = effect_actuator_component.modified_attributes(base_attributes)
	
	assert_eq(final_attributes.health, 30, "Health should be increased by 10")

func test_modified_hit_effect():
	var mock_relic_script = GDScript.new()
	mock_relic_script.source_code = """
extends Effect
func modify_hit_effect(hit_effect: HitEffect, _target: Node, logger: Callable = Callable()) -> void:
	hit_effect.damage += 5
	if logger.is_valid():
		logger.call("Added 5 damage")
"""
	mock_relic_script.reload()
	
	var mock_relic_def = RelicDef.new()
	mock_relic_def.name = &"Damage Buff Relic"
	var mock_types: Array[int] = [EffectDef.EffectType.HIT_EFFECT]
	mock_relic_def.effect_types = mock_types
	mock_relic_def.effect_script = mock_relic_script
	
	effect_actuator_component.add_relic(mock_relic_def)
	
	var base_hit = HitEffect.new()
	base_hit.damage = 10
	var effect_log: Array[String] = []
	var final_hit = effect_actuator_component.modified_hit_effect(base_hit, null, effect_log)
	
	assert_eq(final_hit.damage, 15, "Damage should be increased by 5")
	assert_eq(effect_log.size(), 1, "Should have logged one message")
	assert_eq(effect_log[0], "Added 5 damage", "Log message should match")

func test_modified_cooldown():
	var mock_relic_script = GDScript.new()
	mock_relic_script.source_code = """
extends Effect
func modified_action_cooldown(action_def: ActionDef, cooldown: float, logger: Callable = Callable()) -> float:
	if logger.is_valid():
		logger.call("Halved cooldown")
	return cooldown * 0.5
"""
	mock_relic_script.reload()
	
	var mock_relic_def = RelicDef.new()
	mock_relic_def.name = &"Cooldown Reduction Relic"
	var mock_types: Array[int] = [EffectDef.EffectType.ACTION_COOLDOWN]
	mock_relic_def.effect_types = mock_types
	mock_relic_def.effect_script = mock_relic_script
	
	effect_actuator_component.add_relic(mock_relic_def)
	
	var dummy_action_def = ActionDef.new()
	var effect_log: Array[String] = []
	var final_cooldown = effect_actuator_component.modified_cooldown(dummy_action_def, 4.0, effect_log)
	
	assert_eq(final_cooldown, 2.0, "Cooldown should be halved")
	assert_eq(effect_log.size(), 1, "Should have logged one message")
	assert_eq(effect_log[0], "Halved cooldown", "Log message should match")
