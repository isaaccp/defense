@tool
extends Node

class_name EffectActuatorComponent

const component = &"EffectActuatorComponent"

@export_group("Required")
@export var status_component: StatusComponent

signal able_to_act_changed(can_act: bool)
signal attribute_effects_changed

# TODO: Move to a single place if https://github.com/godotengine/godot-proposals/issues/6416 is implemented.
var running = false

var effect_by_name: Dictionary
var effect_script_by_name: Dictionary
var effect_script_by_effect_type: Dictionary

var unable_to_act_count = 0:
	set(value):
		if unable_to_act_count == 0 and value > 0:
			able_to_act_changed.emit(false)
		elif unable_to_act_count > 0 and value == 0:
			able_to_act_changed.emit(true)
		unable_to_act_count = value

func run():
	if running:
		assert(false, "run() called twice on %s" % component)
	running = true
	status_component.status_added.connect(_on_status_added)
	status_component.status_removed.connect(_on_status_removed)

func modified_attributes(base_attributes: Attributes) -> Attributes:
	var attributes = base_attributes.duplicate(true)
	for effect_script in effect_script_by_effect_type.get(EffectDef.EffectType.ATTRIBUTE, []):
		effect_script.modify_attributes(attributes)
	return attributes

func _on_status_added(status: StatusDef):
	_add_effect(status)

func _on_status_removed(status_name: StringName):
	_remove_effect(status_name)

func _add_effect(effect: EffectDef):
	effect_by_name[effect.name] = effect
	var script = effect.effect_script.new() as Effect
	effect_script_by_name[effect.name] = script
	# Some effect types may not require tracking like this, but unless it
	# becomes a problem it's probably fine to track anyway.
	for effect_type in effect.effect_types:
		if not effect_type in effect_script_by_effect_type:
			effect_script_by_effect_type[effect_type] = []
		effect_script_by_effect_type[effect_type].append(script)
		match effect_type:
			EffectDef.EffectType.ABLE_TO_ACT:
				script.able_to_act.connect(_on_able_to_act_changed)
			EffectDef.EffectType.ATTRIBUTE:
				attribute_effects_changed.emit()
	script.on_effect_added()

func _remove_effect(effect_name: StringName):
	var script = effect_script_by_name[effect_name] as Effect
	script.on_effect_removed()
	effect_script_by_name.erase(effect_name)
	var effect = effect_by_name[effect_name] as EffectDef
	for effect_type in effect.effect_types:
		effect_script_by_effect_type[effect_type].erase(script)
		match effect_type:
			EffectDef.EffectType.ATTRIBUTE:
				attribute_effects_changed.emit()
	effect_by_name.erase(effect_name)

func _on_able_to_act_changed(can_act: bool):
	if can_act:
		unable_to_act_count -= 1
	else:
		unable_to_act_count += 1

func _get_configuration_warnings():
	var warnings = PackedStringArray()
	if not status_component:
		warnings.append("Must set status_component")
	return warnings
