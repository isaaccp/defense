extends Skill

class_name ParamSkill

@export var params: SkillParams = SkillParams.new()
# If true, it means it hasn't been parameterized through editor. Can't
# be used in a rule, etc.
@export var abstract = true

func name() -> String:
	assert(false, "Must be implemented by subclasses")
	return "<name>"

func _to_string() -> String:
	if not params or params.placeholders.size() == 0:
		return name()
	else:
		return params.interpolated_text()
