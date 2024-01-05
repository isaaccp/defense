@tool
extends Node

class_name AnimationComponent

const component = &"AnimationComponent"

@export_group("Required")
@export var animation_player: AnimationPlayer

@export_group("Optional")
# Optional fields.

func play_animation(animation: String, wait: bool = true) -> bool:
	if animation_player.has_animation(animation):
		animation_player.play(animation)
		if wait:
			await animation_player.animation_finished
		return true
	return false

func stop_animation(animation: String) -> bool:
	if animation_player.current_animation == animation:
		animation_player.stop()
		return true
	return false

static func get_or_null(node) -> AnimationComponent:
	return Component.get_or_null(node, component) as AnimationComponent

static func get_or_die(node) -> AnimationComponent:
	var c = get_or_null(node)
	assert(c)
	return c

func _get_configuration_warnings():
	var warnings = PackedStringArray()
	if not get_parent() is Node2D:
		return warnings
	if not animation_player:
		warnings.append("This component requires an AnimationPlayer set (can be a child)")
	return warnings
