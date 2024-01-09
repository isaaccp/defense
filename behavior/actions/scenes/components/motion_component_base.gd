extends Node2D

class_name MotionComponentBase

@export_group("Required")
@export var action_scene: ActionScene

var done = false

signal motion_done

func _physics_process(_delta: float):
	if done:
		return

func mark_done():
	motion_done.emit()
	done = true
