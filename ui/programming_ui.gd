extends Control

class_name ProgrammingUI

var character: Character

signal done

func initialize(character_: Character):
	# TODO: Actually filter those depending on character, etc.
	character = character_
	%Toolbox.initialize(
		TargetSelectionManager.all_target_selections(),
		ActionManager.all_actions(),
	)

func _ready():
	%Script.load_behavior(character.behavior)

func _on_save_button_pressed():
	# character.behavior = ...
	done.emit()

func _on_cancel_button_pressed():
	done.emit()
