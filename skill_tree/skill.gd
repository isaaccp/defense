@tool
extends Resource

class_name Skill

enum SkillType {
	UNSPECIFIED,
	ACTION,
	TARGET,
	CONDITION,
	TARGET_SORT,
	META,
}

@export var skill_name: StringName
@export var skill_type: SkillType
@export var parent: Skill
@export var tree_type: SkillTree.TreeType

func type_name() -> String:
	return SkillType.keys()[skill_type]

static func skill_type_filesystem_string(skill_type: SkillType) -> String:
	assert(skill_type != SkillType.UNSPECIFIED)
	return SkillType.keys()[skill_type].to_lower()

func full_description():
	assert(false, "implement in subclass")

func _to_string() -> String:
	return skill_name
