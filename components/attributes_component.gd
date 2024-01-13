extends Node

class_name AttributesComponent

@export_group("Required")
@export var base_attributes: Attributes

@export_group("Optional")
@export var status_component: StatusComponent

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
	if status_component:
		status_component.statuses_changed.connect(_on_statuses_changed)
		_on_statuses_changed()
	else:
		attributes = base_attributes

func resistance_multiplier_for(damage_type: DamageType) -> float:
	for r in attributes.resistance:
		if r.damage_type == damage_type:
			return r.multiplier()
	return 1.0

func _on_statuses_changed(_statuses: Array[StatusDef.Id] = []):
	attributes = status_component.adjusted_attributes(base_attributes)
