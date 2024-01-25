@tool
extends Resource

## Minimal data that needs to be saved for a Skill to restore it.
class_name StoredSkill

## Skill name. Identifier for the skill.
@export var name: StringName
## The namespace are not disjoint, so need to know the type to restore.
@export var skill_type: Skill.SkillType

static func from_skill(skill: Skill) -> StoredSkill:
	var stored_skill = StoredSkill.new()
	stored_skill.name = skill.skill_name
	stored_skill.skill_type = skill.skill_type
	return stored_skill
