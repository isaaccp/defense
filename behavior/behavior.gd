extends Resource

class_name Behavior

@export var rules: Array[Rule]

# TODO: Return BehaviorResult or such.
func choose(body: CharacterBody2D, side_component: SideComponent) -> Dictionary:
	for rule in rules:
		# TODO: Construct actions only once when added to the behavior.
		var action = ActionManager.make_action(rule.action)
		var target = TargetSelectionManager.select_target(body, side_component, action, rule.target_selection)
		if target.valid():
			return {"rule": rule, "target": target, "action": action}
	return {}

func serialize() -> PackedByteArray:
	var data = []
	for rule in rules:
		var rule_dict = {
			"target": rule.target_selection.id,
			"action": rule.action.id,
		}
		data.append(rule_dict)
	return var_to_bytes(data)

static func deserialize(serialized_behavior: PackedByteArray) -> Behavior:
	var behavior = Behavior.new()
	var data = bytes_to_var(serialized_behavior)
	for serialized_rule in data:
		var rule = Rule.new()
		rule.target_selection = TargetSelectionDef.make(serialized_rule.target)
		rule.action = ActionDef.make(serialized_rule.action)
		behavior.rules.append(rule)
	return behavior

func _to_string() -> String:
	var result = ""
	for rule in rules:
		result += "%s\n" % str(rule)
	return result
