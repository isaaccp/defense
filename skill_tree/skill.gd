@tool
extends Resource

class_name Skill

enum SkillType {
	UNSPECIFIED,
	ACTION,
	TARGET,
}

@export var skill_type: SkillType
@export var action_def: ActionDef
@export var target_selection_def: TargetSelectionDef
@export var parent: Skill
