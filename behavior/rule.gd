extends Resource

class_name Rule

@export var target_selection: TargetSelectionDef
@export var action: ActionDef

func _to_string() -> String:
	return "Target Selection: %s Action: %s" % [
		target_selection,
		action,
	]

static func make(target_selection: TargetSelectionDef, action: ActionDef) -> Rule:
	var rule = Rule.new()
	rule.target_selection = target_selection
	rule.action = action
	return rule
