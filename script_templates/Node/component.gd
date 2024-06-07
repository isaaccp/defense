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

func _get_configuration_warnings():
	var warnings = PackedStringArray()
	# TODO
	return warnings
