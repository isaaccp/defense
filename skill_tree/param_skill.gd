extends Skill

class_name ParamSkill

@export var params: SkillParams = SkillParams.new()

# Parameters from params that need to be restored from stored behavior (e.g. target sort).
var restored_skill_params: RestoredSkillParams = RestoredSkillParams.new()

func name() -> String:
	assert(false, "Must be implemented by subclasses")
	return "<name>"

func required_skills() -> Array[StringName]:
	var skills: Array[StringName] = []
	skills.append(skill_name)
	if params.placeholder_set(SkillParams.PlaceholderId.SORT):
		var target_sort = params.get_placeholder_value(SkillParams.PlaceholderId.SORT) as StoredSkill
		skills.append(target_sort.name)
	return skills

func _to_string() -> String:
	if not params or params.placeholders.size() == 0:
		return name()
	else:
		return params.interpolated_text()

func clone() -> Skill:
	var param_skill: ParamSkill = duplicate()
	param_skill.params = params.duplicate(true)
	return param_skill
