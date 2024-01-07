@tool
extends Resource

## Minimal data that needs to be saved for a rule in Behavior to be able to
## restore it.
class_name RuleSkillDef

## DEPRECATED. See name. Skill identifier, can be ActionDef.Id, TargetSelectionDef.Id, etc.
@export var id: int
## Skill name. Identifier for the skill.
@export var name: StringName
## The namespace are not disjoint, so need to know the type to restore.
@export var skill_type: Skill.SkillType
## Parameters configured for the skill.
@export var params: SkillParams

func _init():
	# TODO: Remove.
	# This was added for the migration from id -> name. No longer needed likely
	# but checking it in in case I need to refert to this for other
	# migrations.
	# Once this bit is written, just need to reload the editor, click on
	# Save All Scenes and all resources should get updated.
	_populate_name.call_deferred()

func _populate_name():
	if name.is_empty():
		var skill = SkillManager.restore_skill(self)
		if skill:
			name = skill.skill_name
			emit_changed()
		else:
			print("failed to populate name")

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
