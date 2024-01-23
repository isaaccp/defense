extends Skill

class_name ParamSkill

@export var params: SkillParams = SkillParams.new()
# If true, it means it hasn't been parameterized through editor. Can't
# be used in a rule, etc.
@export var abstract = true

func name() -> String:
	assert(false, "Must be implemented by subclasses")
	return "<name>"

func required_skills() -> Array[StringName]:
	var skills: Array[StringName] = []
	skills.append(skill_name)
	if params.placeholder_set(SkillParams.PlaceholderId.SORT):
		var target_sort = params.get_placeholder_value(SkillParams.PlaceholderId.SORT) as TargetSort
		skills.append(target_sort.skill_name)
	return skills

func _to_string() -> String:
	if not params or params.placeholders.size() == 0:
		return name()
	else:
		return params.interpolated_text()
