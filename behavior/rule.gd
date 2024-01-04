extends Resource

class_name Rule

@export var target_selection: TargetSelectionDef
@export var action: ActionDef
@export var condition: ConditionDef

func _to_string() -> String:
	return "%s -> %s (%s)" % [
		action.name(),
		target_selection.name(),
		condition.name(),
	]

static func make(target_selection: TargetSelectionDef, action: ActionDef, condition: ConditionDef = ConditionManager.make_instance(ConditionDef.Id.ALWAYS)) -> Rule:
	var rule = Rule.new()
	rule.target_selection = target_selection
	rule.action = action
	assert(not condition.abstract)
	rule.condition = condition
	return rule
