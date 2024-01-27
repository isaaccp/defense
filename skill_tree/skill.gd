@tool
extends Resource

class_name Skill

enum SkillType {
	UNSPECIFIED,
	ACTION,
	TARGET,
	CONDITION,
	TARGET_SORT,
	META_SKILL,
}

enum TreeType {
	UNSPECIFIED,
	GENERAL,
	WARRIOR,
	ROGUE,
	CLERIC,
	WIZARD,
	META,
}

@export var skill_name: StringName
@export var skill_type: SkillType
@export var parent: Skill
@export var tree_type: Skill.TreeType

func type_name() -> String:
	return SkillType.keys()[skill_type].capitalize()

static func skill_type_filesystem_string(skill_type: SkillType) -> String:
	assert(skill_type != SkillType.UNSPECIFIED)
	return SkillType.keys()[skill_type].to_lower()

func description():
	assert(false, "implement in subclass")

func required_skills() -> Array[StringName]:
	return [skill_name]

func _to_string() -> String:
	return skill_name

## Creates a new copy of the Skill. Each subclass should only copy the minimum
## amount required, otherwise maintain references to same objects.
func clone() -> Skill:
	return duplicate()
