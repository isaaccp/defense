@tool
extends Node

class_name VitalsComponent

const component: StringName = &"VitalsComponent"

enum VitalType {
	HEALTH,
	FOCUS,
}

class VitalUpdate extends RefCounted:
	var type: VitalType
	var current_value: float
	var prev_value: float
	var max_value: float
	var is_increase: bool

	func _to_string() -> String:
		return "[%s: %.2f -> %.2f (max: %.2f)]" % [VitalType.keys()[type], prev_value, current_value, max_value]

signal vital_updated(update: VitalUpdate)
signal vital_depleted(type: VitalType)

@export_group("Required")
@export var attributes_component: AttributesComponent

@export_group("Optional")
@export var logging_component: LoggingComponent

# A dictionary to hold the current and max values for all vital types.
# This makes the component data-driven and easy to extend.
# Format: { VitalType.HEALTH: {current: 100.0, max: 100.0}, ... }

var _vitals_data: Dictionary[VitalType, Dictionary] = {}
var _is_initialized: bool = false

var running = false

func _ready():
	if Engine.is_editor_hint():
		return
	_initialize.call_deferred()

func _initialize() -> void:
	var max_health = float(attributes_component.health)
	_vitals_data[VitalType.HEALTH] = {"current": 0.0, "max": max_health}
	
	if max_health > 0:
		apply_vital_change(VitalType.HEALTH, max_health, false)
	
	var max_focus = float(attributes_component.focus)
	_vitals_data[VitalType.FOCUS] = {"current": 0.0, "max": max_focus}
	
	if max_focus > 0:
		apply_vital_change(VitalType.FOCUS, max_focus, false)

	if attributes_component and not attributes_component.attributes_changed.is_connected(_on_attributes_changed):
		attributes_component.attributes_changed.connect(_on_attributes_changed)

	_is_initialized = true

# The primary method for changing a vital's value.
# Use positive delta for healing/gaining, negative for damage/spending.
func apply_vital_change(type: VitalType, delta: float, should_log: bool = true) -> void:
	if not _vitals_data.has(type):
		push_error("apply_vital_change called with unknown VitalType: %s" % type)
		return

	var vital = _vitals_data[type]
	var prev_value = vital.current
	
	# Apply the change and clamp it between 0 and the max value.
	vital.current = clampf(vital.current + delta, 0, vital.max)

	# If there was no actual change, do nothing further.
	if is_equal_approx(vital.current, prev_value):
		return

	# Create and emit the update signal.
	var update = VitalUpdate.new()
	update.type = type
	update.current_value = vital.current
	update.prev_value = prev_value
	update.max_value = vital.max
	update.is_increase = vital.current > prev_value
	vital_updated.emit(update)

	if should_log:
		_log(str(update))

	if is_equal_approx(vital.current, 0):
		vital_depleted.emit(type)

func get_vital_current(type: VitalType) -> float:
	if _vitals_data.has(type):
		return _vitals_data[type].current
	return 0.0

func get_vital_max(type: VitalType) -> float:
	if _vitals_data.has(type):
		return _vitals_data[type].max
	return 0.0
	
# Just for testing, set's vital current.
func test_set_vital_current(type: VitalType, new_value: float) -> void:
	assert(_vitals_data.has(type))
	_vitals_data[type].current = new_value
	
func run():
	running = true

func stop():
	running = false

func _process(delta: float) -> void:
	if running:
		var focus_regen = attributes_component.focus_regen
		var focus_recovery = focus_regen * delta
		apply_vital_change(VitalsComponent.VitalType.FOCUS, focus_recovery, false)
		var health_regen = attributes_component.health_regen
		if health_regen > 0:
			apply_vital_change(VitalsComponent.VitalType.HEALTH, health_regen * delta, false)
		
func _log(message: String, tooltip: String = ""):
	if not logging_component:
		return
	logging_component.add_log_entry(LoggingComponent.LogType.VITALS, message, tooltip)

func _on_attributes_changed() -> void:
	if not _is_initialized:
		return
	
	var health_vital = _vitals_data[VitalType.HEALTH]
	var new_max_health = float(attributes_component.health)
	if not is_equal_approx(health_vital.max, new_max_health):
		var old_max = health_vital.max
		var old_current = health_vital.current
		var diff = new_max_health - old_max
		health_vital.max = new_max_health
		if diff > 0:
			health_vital.current = clampf(health_vital.current + diff, 0, new_max_health)
		else:
			health_vital.current = clampf(health_vital.current, 0, new_max_health)
		
		var update = VitalUpdate.new()
		update.type = VitalType.HEALTH
		update.current_value = health_vital.current
		update.prev_value = old_current
		update.max_value = new_max_health
		update.is_increase = new_max_health > old_max
		vital_updated.emit(update)

	var focus_vital = _vitals_data[VitalType.FOCUS]
	var new_max_focus = float(attributes_component.focus)
	if not is_equal_approx(focus_vital.max, new_max_focus):
		var old_max = focus_vital.max
		var old_current = focus_vital.current
		var diff = new_max_focus - old_max
		focus_vital.max = new_max_focus
		if diff > 0:
			focus_vital.current = clampf(focus_vital.current + diff, 0, new_max_focus)
		else:
			focus_vital.current = clampf(focus_vital.current, 0, new_max_focus)
		
		var update = VitalUpdate.new()
		update.type = VitalType.FOCUS
		update.current_value = focus_vital.current
		update.prev_value = old_current
		update.max_value = new_max_focus
		update.is_increase = new_max_focus > old_max
		vital_updated.emit(update)
