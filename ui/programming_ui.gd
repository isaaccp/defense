extends Control

class_name ProgrammingUI

func initialize(character: Character):
	# TODO: Parse behavior in character and initialize script from it.
	# TODO: Actually filter those depending on character, etc.
	%Toolbox.initialize(
		TargetSelectionManager.all_target_selections(),
		ActionManager.all_actions(),
	)
