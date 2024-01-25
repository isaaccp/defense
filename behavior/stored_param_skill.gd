@tool
extends StoredSkill

## Minimal data that needs to be saved for a ParamsSkill to restore it.
class_name StoredParamSkill

## Parameters configured for the skill.
@export var params: SkillParams

static func from_skill(skill: Skill) -> StoredSkill:
	var param_skill = skill as ParamSkill
	if param_skill:
		return StoredParamSkill.from_param_skill(param_skill)
	return StoredSkill.from_skill(skill)

static func from_param_skill(skill: ParamSkill) -> StoredParamSkill:
	var stored_param_skill = StoredParamSkill.new()
	stored_param_skill.name = skill.skill_name
	stored_param_skill.skill_type = skill.skill_type
	stored_param_skill.params = skill.params
	return stored_param_skill
