extends Resource

class_name Behavior

@export var rules: Array[Rule]

# TODO: Return BehaviorResult or such.
func choose(entity: BehaviorEntity) -> Dictionary:
	for rule in rules:
		# TODO: Construct actions only once when added to the behavior.
		var action = ActionManager.make_action(rule.action)
		var target = TargetSelectionManager.select_target(entity, action, rule.target_selection)
		if target:
			return {"rule": rule, "target": target, "action": action}
	return {}
