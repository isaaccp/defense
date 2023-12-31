extends Node2D

class_name Character

@export_group("Required")
@export var health_component: HealthComponent
@export var behavior_component: BehaviorComponent

@export_group("debug")
@export var id: Enum.CharacterId
@export var idx: int
@export var peer_id: int

var behavior: Behavior:
	set(value):
		behavior_component.behavior = value
	get:
		return behavior_component.behavior

func short_name() -> String:
	return "%s (%d)" % [Enum.character_id_string(id), idx]
