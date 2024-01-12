extends Node

class_name AttributesComponent

@export_group("Required")
@export var base_attributes: Attributes

@export_group("Optional")
@export var status_component: StatusComponent

var speed: float:
	get:
		if status_component:
			return status_component.adjusted_speed(base_attributes.speed)
		else:
			return base_attributes.speed
var health: int:
	get:
		if status_component:
			return status_component.adjusted_health(base_attributes.health)
		else:
			return base_attributes.health
var damage_multiplier:
	get:
		if status_component:
			return status_component.adjusted_damage_multiplier(base_attributes.damage_multiplier)
		else:
			return base_attributes.damage_multiplier
