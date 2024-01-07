extends Skill

class_name ParamSkill

@export var params: SkillParams = SkillParams.new()
# If true, it means it hasn't been parameterized through editor. Can't
# be used in a rule, etc.
@export var abstract = true

func name() -> String:
	assert(false, "Must be implemented by subclasses")
	return "<name>"

func rule_skill_def() -> RuleSkillDef:
	var rule_skill = super()
	rule_skill.params = params
	return rule_skill

func _to_string() -> String:
	if not params or params.placeholders.size() == 0:
		return name()
	else:
		return params.interpolated_text()
