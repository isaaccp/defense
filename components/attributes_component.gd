@tool
extends Node

class_name AttributesComponent

const component = &"AttributesComponent"

@export_group("Optional")
## Base attributes for the unit, required for enemies.
## Characters set it from the GameplayCharacter.
@export var base_attributes: Attributes
@export var effect_actuator_component: EffectActuatorComponent

var attributes: Attributes

var speed: float:
	get: return attributes.speed
	set(value): pass
var health: int:
	get: return attributes.health
	set(value): pass
var damage_multiplier: float:
	get: return attributes.damage_multiplier
	set(value): pass
var armor: int:
	get: return attributes.armor
	set(value): pass
var resistance: Array[Resistance]:
	get: return attributes.resistance
	set(value): pass

func _ready():
	if Engine.is_editor_hint():
		return
	if effect_actuator_component:
		effect_actuator_component.attribute_effects_changed.connect(_on_attribute_effects_changed)
		_on_attribute_effects_changed()
	else:
		attributes = base_attributes

func resistance_multiplier_for(attack_type: AttackType, damage_type: DamageType) -> float:
	return attributes.resistance_multiplier_for(attack_type, damage_type)

func _on_attribute_effects_changed():
	attributes = effect_actuator_component.modified_attributes(base_attributes)

static func get_or_null(node) -> AttributesComponent:
	return Component.get_or_null(node, component) as AttributesComponent

static func get_or_die(node) -> AttributesComponent:
	var c = get_or_null(node)
	assert(c)
	return c

func _get_configuration_warnings():
	var warnings = PackedStringArray()
	if not get_parent() is Node2D:
		return warnings
	return warnings
