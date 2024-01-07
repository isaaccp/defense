@tool
extends Resource

class_name Skill

enum SkillType {
	UNSPECIFIED,
	ACTION,
	TARGET,
	CONDITION,
	TARGET_SORT,
}

@export var skill_name: StringName
@export var skill_type: SkillType
@export var parent: Skill
@export var tree_type: SkillTree.TreeType

func type_name() -> String:
	return SkillType.keys()[skill_type]

func rule_skill_def() -> RuleSkillDef:
	var rule_skill = RuleSkillDef.new()
	# All subclasses provide id but they are different enums so can't
	# declare it here.
	rule_skill.id = get("id")
	rule_skill.name = skill_name
	rule_skill.skill_type = skill_type
	return rule_skill

static func skill_type_filesystem_string(skill_type: SkillType) -> String:
	assert(skill_type != SkillType.UNSPECIFIED)
	return SkillType.keys()[skill_type].to_lower()

func _to_string() -> String:
	return skill_name
