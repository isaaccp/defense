@tool
extends Node

class_name SpawnAnimationControllerComponent

const component = &"SpawnAnimationControllerComponent"

@export_group("Required")
@export var animation_component: AnimationComponent
# E.g. if the spawner is a "house", then you want it to show from load.
# If it's a "portal", you want it to show up later.
@export var show_on_level_start: bool

func _ready():
	# Do not hide this on the editor!
	if Engine.is_editor_hint():
		return
	if not show_on_level_start:
		animation_component.hide()

# Those are not signal-driven because we want them to be awaitable
# coroutines.
func on_spawning_start():
	animation_component.show()
	await animation_component.play_animation("spawning_start")
	animation_component.play_animation("permanent")

func on_spawn():
	await animation_component.play_animation("spawn")
	animation_component.play_animation("permanent")

func on_spawning_end():
	await animation_component.play_animation("spawning_end")
	if not show_on_level_start:
		animation_component.stop_animation("permanent")
		animation_component.hide()

static func get_or_null(node) -> SpawnAnimationControllerComponent:
	return Component.get_or_null(node, component) as SpawnAnimationControllerComponent

static func get_or_die(node) -> SpawnAnimationControllerComponent:
	var c = get_or_null(node)
	assert(c)
	return c
