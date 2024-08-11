@tool
extends Node2D

# Eventually this class should inherit from CharacterBody2D but that will break all the scenes
# that inherit from BaseCharacter and BaseEnemy. For now, it'll just have an exported
# character_body that can be set in the current scenes.
class_name CharacterBodyComponent

const component = &"CharacterBodyComponent"

@export_group("Required")
@export var character_body: CharacterBody2D

# TODO: Move to a single place if https://github.com/godotengine/godot-proposals/issues/6416 is implemented.
var running = false

func run():
	if running:
		assert(false, "run() called twice on %s" % component)
	running = true

func _get_configuration_warnings():
	var warnings = PackedStringArray()
	if not get_parent() is Node2D:
		return warnings
	if not character_body:
		warnings.append("This component requires character_body to be set")
	return warnings
