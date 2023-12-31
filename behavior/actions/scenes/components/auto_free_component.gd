extends Node

class_name AutoFreeComponent

@export_group("Required")
@export var animation_player: AnimationPlayer
@export var free_on_finished = true

# Called when the node enters the scene tree for the first time.
func _ready():
	if free_on_finished:
		animation_player.animation_finished.connect(
			func(_anim):
				var parent = get_parent()
				if is_instance_valid(parent):
					parent.queue_free()
		)
