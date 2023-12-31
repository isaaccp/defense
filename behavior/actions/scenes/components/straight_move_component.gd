extends Node2D

class_name StraightMoveComponent

@export_group("Required")
@export var action_scene: ActionScene
@export var speed: float

func _physics_process(delta: float):
	var dir = Vector2(cos(global_rotation), sin(global_rotation)).normalized()
	action_scene.global_position += dir * speed * delta
