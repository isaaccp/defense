extends Resource

## Minimal data that needs to be saved for a rule in Behavior to be able to
## restore it.
class_name RuleSkillDef

## Skill identifier, can be ActionDef.Id, TargetSelectionDef.Id, etc.
@export var id: int
## The namespace are not disjoint, so need to know the type to restore.
@export var skill_type: Skill.SkillType
## Parameters configured for the skill.
@export var params: SkillParams

static func make(skill_type: Skill.SkillType, id: int, params: SkillParams) -> RuleSkillDef:
	var rule_skill = RuleSkillDef.new()
	rule_skill.id = id
	rule_skill.skill_type = skill_type
	rule_skill.params = params
	return rule_skill

static func make_target(id: int, params: SkillParams = null) -> RuleSkillDef:
	return make(Skill.SkillType.TARGET, id, params)

static func make_condition(id: int, params: SkillParams = null) -> RuleSkillDef:
	return make(Skill.SkillType.CONDITION, id, params)

static func make_action(id: int, params: SkillParams = null) -> RuleSkillDef:
	return make(Skill.SkillType.ACTION, id, params)
