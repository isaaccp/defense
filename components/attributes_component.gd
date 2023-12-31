extends Node

class_name AttributesComponent

@export_group("Required")
@export var speed: float:
	get:
		if status_component:
			return status_component.adjusted_speed(speed)
		else:
			return speed
@export var health: int:
	get:
		if status_component:
			return status_component.adjusted_health(health)
		else:
			return health
@export var damage_multiplier = 1.0:
	get:
		if status_component:
			return status_component.adjusted_damage_multiplier(damage_multiplier)
		else:
			return damage_multiplier

@export_group("Optional")
@export var status_component: StatusComponent
