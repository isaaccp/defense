@tool
extends Resource

class_name RuleDef

@export var target_selection: StoredParamSkill
@export var action: StoredParamSkill
## @deprecated: kept for backward compatibility with older saved data. New
## code should write to `conditions` instead. Use `effective_conditions()`
## when reading.
@export var condition: StoredParamSkill
## Conditions are ANDed together — a rule fires only if all of them pass.
## The max allowed is gated by the player's meta-skills (default 1; Compound
## Conditions unlocks 2; Triple Conditions unlocks 3).
@export var conditions: Array[StoredParamSkill]

## Returns the effective list of conditions: the new `conditions` array if
## populated, otherwise the legacy single `condition` wrapped in an array.
func effective_conditions() -> Array[StoredParamSkill]:
	if not conditions.is_empty():
		return conditions
	if condition:
		var single: Array[StoredParamSkill] = [condition]
		return single
	return []

func required_skills() -> Array[StringName]:
	var skills: Array[StringName] = []
	skills.append(target_selection.name)
	if target_selection.params.placeholder_set(SkillParams.PlaceholderId.SORT):
		var stored_sort = target_selection.params.get_placeholder_value(SkillParams.PlaceholderId.SORT) as StoredSkill
		skills.append(stored_sort.name)
	skills.append(action.name)
	for c in effective_conditions():
		skills.append(c.name)
	return skills

func _to_string() -> String:
	var names := PackedStringArray()
	for c in effective_conditions():
		names.append(c.name)
	return "%s -> %s (%s)" % [
		action.name,
		target_selection.name,
		", ".join(names),
	]

static func make(target_selection: StoredParamSkill, action: StoredParamSkill, condition: StoredParamSkill) -> RuleDef:
	var rule = RuleDef.new()
	rule.target_selection = target_selection
	rule.action = action
	rule.condition = condition
	return rule

static func make_with_conditions(target_selection: StoredParamSkill, action: StoredParamSkill, conditions: Array[StoredParamSkill]) -> RuleDef:
	var rule = RuleDef.new()
	rule.target_selection = target_selection
	rule.action = action
	rule.conditions = conditions
	return rule
