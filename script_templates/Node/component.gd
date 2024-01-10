@tool
extends Node

class_name NewComponent

const component = &"NewComponent"

@export_group("Required")
# TODO: Required fields.

@export_group("Optional")
# TODO: Optional fields.

# TODO: Move to a single place if https://github.com/godotengine/godot-proposals/issues/6416 is implemented.
var running = false

func run():
	if running:
		assert(false, "run() called twice on %s" % component)
	running = true

static func get_or_null(node: Node) -> NewComponent:
	return Component.get_or_null(node, component) as NewComponent

static func get_or_die(node: Node) -> NewComponent:
	var c = get_or_null(node)
	assert(c)
	return c

func _get_configuration_warnings():
	var warnings = PackedStringArray()
	if not get_parent() is Node2D:
		return warnings
	# TODO
	return warnings

