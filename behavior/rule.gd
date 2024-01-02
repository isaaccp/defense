extends Resource

class_name Rule

@export var target_selection: TargetSelectionDef
@export var action: ActionDef
@export var condition: ConditionDef

func _to_string() -> String:
	return "Target Selection: %s Action: %s Condition: %s" % [
		target_selection,
		action,
		condition,
	]

static func make(target_selection: TargetSelectionDef, action: ActionDef) -> Rule:
	var rule = Rule.new()
	rule.target_selection = target_selection
	rule.action = action
	# TODO: Stop hardcoding and pass along.
	rule.condition = ConditionDef.make_instance(ConditionDef.Id.ALWAYS, ConditionDef.Type.ANY)
	return rule
