@tool
extends Resource

# TODO: Rename Skill when finished.
class_name Skill

enum SkillType {
	UNSPECIFIED,
	ACTION,
	TARGET,
	CONDITION,
}

@export var skill_name: StringName
@export var skill_type: SkillType
@export var parent: Skill
@export var tree_type: SkillTree.TreeType

func type_name() -> String:
	return SkillType.keys()[skill_type]

# TODO: Temporary for compatibility with Skill.
func get_id() -> int:
	return 0

static func skill_type_filesystem_string(skill_type: SkillType) -> String:
	assert(skill_type != SkillType.UNSPECIFIED)
	return SkillType.keys()[skill_type].to_lower()
