extends Node

class_name SkillManagerComponent

const component = &"SkillManagerComponent"

@export_group("Debug")

func target_types() -> Array:
	return TargetSelectionManager.all_target_selections()

func actions() -> Array:
	return ActionManager.all_actions()
