@tool
extends Resource

class_name RuleDef

@export var target_selection: RuleSkillDef
@export var action: RuleSkillDef
@export var condition: RuleSkillDef

func required_skills() -> Array[StringName]:
	var skills: Array[StringName] = []
	skills.append(target_selection.name)
	if target_selection.params.placeholder_set(SkillParams.PlaceholderId.SORT):
		var target_sort = target_selection.params.get_placeholder_value(SkillParams.PlaceholderId.SORT) as TargetSort
		skills.append(target_sort.name())
	skills.append(action.name)
	skills.append(condition.name)
	return skills

func _to_string() -> String:
	return "%s -> %s (%s)" % [
		action.name,
		target_selection.name,
		condition.name,
	]

static func make(target_selection: RuleSkillDef, action: RuleSkillDef, condition: RuleSkillDef) -> RuleDef:
	var rule = RuleDef.new()
	rule.target_selection = target_selection
	rule.action = action
	rule.condition = condition
	return rule
