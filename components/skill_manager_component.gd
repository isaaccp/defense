extends Node

class_name SkillManagerComponent

const component = &"SkillManagerComponent"

@export_group("Required")
@export var skill_tree_collection: SkillTreeCollection

@export_group("Optional")
# TODO: Make required.
# Without it, we return all available options.
@export var persistent_game_state_component: PersistentGameStateComponent

@export_group("Debug")

var skill_unlock_state: SkillUnlockState:
	get:
		if persistent_game_state_component:
			return persistent_game_state_component.state.skill_unlock_state
		return SkillUnlockState.make_full()
	set(value):
		pass

func target_types() -> Array:
	return skill_unlock_state.target_selections

func actions() -> Array:
	return skill_unlock_state.actions

