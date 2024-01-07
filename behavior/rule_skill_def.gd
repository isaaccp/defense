@tool
extends Resource

## Minimal data that needs to be saved for a rule in Behavior to be able to
## restore it.
class_name RuleSkillDef

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

static func make(skill_type: Skill.SkillType, name: StringName, params: SkillParams) -> RuleSkillDef:
	var rule_skill = RuleSkillDef.new()
	rule_skill.name = name
	rule_skill.skill_type = skill_type
	rule_skill.params = params
	return rule_skill

# TODO: Remove all those as we should be able to just do a lookup
# in make() now that we have a single namespace.

static func make_target(name: StringName, params: SkillParams = null) -> RuleSkillDef:
	return make(Skill.SkillType.TARGET, name, params)

static func make_condition(name: StringName, params: SkillParams = null) -> RuleSkillDef:
	return make(Skill.SkillType.CONDITION, name, params)

static func make_action(name: StringName, params: SkillParams = null) -> RuleSkillDef:
	return make(Skill.SkillType.ACTION, name, params)
