extends Resource

class_name Behavior

@export var rules: Array[Rule]

# TODO: Return BehaviorResult or such.
func choose(entity: BehaviorEntity) -> Dictionary:
	for rule in rules:
		var target = TargetSelectionManager.select_target(entity, rule.target_selection)
		if target:
			return {"rule": rule, "target": target}
	return {}
