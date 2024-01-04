@tool
extends Resource

class_name Skill

enum SkillType {
	UNSPECIFIED,
	ACTION,
	TARGET,
	CONDITION,
}

@export var skill_type: SkillType
@export var action_def: ActionDef
@export var target_selection_def: TargetSelectionDef
@export var condition_def: ConditionDef
@export var parent: Skill
# Not saved but set when loading tree.
var tree_type: SkillTree.TreeType

func name() -> String:
	match skill_type:
		SkillType.ACTION:
			return action_def.name()
		SkillType.TARGET:
			return target_selection_def.name()
		SkillType.CONDITION:
			return condition_def.name()
	assert(false, "Unsupported skill type")
	return "<bug>"

func type_name() -> String:
	return SkillType.keys()[skill_type]

func get_id() -> int:
	match skill_type:
		SkillType.ACTION:
			return action_def.id
		SkillType.TARGET:
			return target_selection_def.id
		SkillType.CONDITION:
			return condition_def.id
	return 0
