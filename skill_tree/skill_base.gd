@tool
extends Resource

# TODO: Rename Skill when finished.
class_name SkillBase

enum SkillType {
	UNSPECIFIED,
	ACTION,
	TARGET,
	CONDITION,
}

@export var skill_name: StringName
@export var skill_type: SkillType
@export var parent: SkillBase
@export var tree_type: SkillTree.TreeType

func type_name() -> String:
	return SkillType.keys()[skill_type]

# TODO: Temporary for compatibility with Skill.
func get_id() -> int:
	return 0
