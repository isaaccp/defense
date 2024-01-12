extends Node

class_name AttributesComponent

@export_group("Required")
@export var base_attributes: Attributes

@export_group("Optional")
@export var status_component: StatusComponent

var attributes: Attributes

var speed: float:
	get: return attributes.speed
var health: int:
	get: return attributes.health
var damage_multiplier: float:
	get: return attributes.damage_multiplier
var armor: int:
	get: return attributes.armor

func _ready():
	if status_component:
		status_component.statuses_changed.connect(_on_statuses_changed)
		_on_statuses_changed()
	else:
		attributes = base_attributes

func _on_statuses_changed(_statuses: Array[StatusDef.Id] = []):
	attributes = status_component.adjusted_attributes(base_attributes)
