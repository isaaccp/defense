extends Resource

class_name Behavior

@export var rules: Array[Rule]

# TODO: Return BehaviorResult or such.
func choose(body: CharacterBody2D, side_component: SideComponent,
			action_cooldowns: Dictionary, elapsed_time: float) -> Dictionary:
	for i in rules.size():
		var rule = rules[i]
		# Check cooldowns.
		if action_cooldowns.has(rule.action.id):
			var can_run_after = action_cooldowns[rule.action.id]
			if elapsed_time < can_run_after:
				continue
		# TODO: Construct actions only once when added to the behavior.
		var target_node_evaluator: TargetNodeConditionEvaluator = null
		match rule.condition.type:
			ConditionDef.Type.ANY:
				var evaluator = SkillManager.make_any_condition_evaluator(rule.condition)
				if not evaluator.evaluate():
					continue
			ConditionDef.Type.SELF:
				var evaluator = SkillManager.make_self_condition_evaluator(rule.condition, body)
				if not evaluator.evaluate():
					continue
			ConditionDef.Type.GLOBAL:
				# TODO: Implement.
				pass
			ConditionDef.Type.TARGET_NODE:
				target_node_evaluator = SkillManager.make_target_node_condition_evaluator(rule.condition)
		var action = SkillManager.make_runnable_action(rule.action)
		var target = Target.make_invalid()
		match rule.target_selection.type:
			Target.Type.NODE:
				var target_selector = SkillManager.make_node_target_selector(rule.target_selection, target_node_evaluator)
				target = target_selector.select_target(action, body, side_component)
		if target.valid():
			return {"id": i, "rule": rule, "target": target, "action": action}
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
		var rule = Rule.make(
			SkillManager.make_target_selection_instance(serialized_rule.target),
			SkillManager.make_action_instance(serialized_rule.action)
		)
		behavior.rules.append(rule)
	return behavior

func _to_string() -> String:
	var result = ""
	for rule in rules:
		result += "%s\n" % str(rule)
	return result
