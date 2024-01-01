extends Node

class_name SkillManagerComponent

const component = &"SkillManagerComponent"

@export_group("Optional")
# TODO: Make required.
# Without it, we return all available options.
@export var persistent_game_state_component: PersistentGameStateComponent

@export_group("Debug")

func target_types() -> Array:
	return TargetSelectionManager.all_target_selections()

func actions() -> Array:
	return ActionManager.all_actions()
