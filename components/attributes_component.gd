extends Node

class_name AttributesComponent

@export_group("Required")
@export var speed: float:
	get:
		return status_component.adjusted_speed(speed)
@export var health: int:
	get:
		return status_component.adjusted_health(health)
@export var damage_multiplier = 1.0:
	get:
		return status_component.adjusted_damage_multiplier(damage_multiplier)
@export var status_component: StatusComponent
