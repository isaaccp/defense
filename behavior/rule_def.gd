@tool
extends Resource

class_name RuleDef

@export var target_selection: StoredParamSkill
@export var action: StoredParamSkill
@export var condition: StoredParamSkill

func required_skills() -> Array[StringName]:
	var skills: Array[StringName] = []
	skills.append(target_selection.name)
	if target_selection.params.placeholder_set(SkillParams.PlaceholderId.SORT):
		var stored_sort = target_selection.params.get_placeholder_value(SkillParams.PlaceholderId.SORT) as StoredSkill
		skills.append(stored_sort.name)
	skills.append(action.name)
	skills.append(condition.name)
	return skills

func _to_string() -> String:
	return "%s -> %s (%s)" % [
		action.name,
		target_selection.name,
		condition.name,
	]

static func make(target_selection: StoredParamSkill, action: StoredParamSkill, condition: StoredParamSkill) -> RuleDef:
	var rule = RuleDef.new()
	rule.target_selection = target_selection
	rule.action = action
	rule.condition = condition
	return rule
