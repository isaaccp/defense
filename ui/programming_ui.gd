extends Control

class_name ProgrammingUI

var character: Character
@onready var script_tree: ScriptTree = %Script

signal canceled
signal saved(behavior: Behavior)

func initialize(character_: Character):
	# TODO: Actually filter those depending on character, etc.
	character = character_
	%Toolbox.initialize(
		TargetSelectionManager.all_target_selections(),
		ActionManager.all_actions(),
	)

func _ready():
	if is_instance_valid(character):
		%Title.text = "Configuring behavior for %s" % character.short_name()
		if character.behavior:
			script_tree.load_behavior(character.behavior)

func _on_save_button_pressed():
	saved.emit(script_tree.get_behavior())

func _on_cancel_button_pressed():
	canceled.emit()
