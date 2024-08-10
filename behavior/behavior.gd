@tool
extends Resource

class_name Behavior

var rules: Array[Rule]
var actor: Actor
var side_component: SideComponent

# TODO: Consider also preparing action if needed.
# It would allow to do things like "every time you use this action, it
# does extra damage", which is neat, with the caveat that likely for
# actions we would like to share across rules, unlike for the other ones,
# i.e., instead of an Array a Dictionary by action.id.
var target_selectors: Array[TargetSelector] = []
var condition_evaluators: Array[ConditionEvaluator] = []

static func restore(stored_behavior: StoredBehavior) -> Behavior:
	var behavior = Behavior.new()
	for stored_rule in stored_behavior.stored_rules:
		var rule = SkillManager.restore_rule(stored_rule)
		behavior.rules.append(rule)
	return behavior

func prepare(actor_: Actor, side_component_: SideComponent):
	actor = actor_
	side_component = side_component_
	target_selectors.clear()
	condition_evaluators.clear()
	for rule in rules:
		var evaluator: ConditionEvaluator = null
		var target_selector: TargetSelector = null
		# Create evaluators that are not target related.
		match rule.condition.type:
			ConditionDef.Type.ANY:
				evaluator = ConditionEvaluatorFactory.make_any_condition_evaluator(rule.condition)
			ConditionDef.Type.SELF:
				evaluator = ConditionEvaluatorFactory.make_self_condition_evaluator(rule.condition, actor)
			ConditionDef.Type.GLOBAL:
				# TODO: Implement.
				pass
		match rule.target_selection.type:
			Target.Type.ACTOR:
				var target_evaluator = ConditionEvaluatorFactory.make_target_actor_condition_evaluator(rule.condition, actor)
				target_selector = TargetSelectorFactory.make_actor_target_selector(rule.target_selection, target_evaluator)
			Target.Type.POSITION:
				var position_evaluator = ConditionEvaluatorFactory.make_position_condition_evaluator(rule.condition, actor)
				target_selector = TargetSelectorFactory.make_position_target_selector(rule.target_selection, position_evaluator)
		target_selectors.append(target_selector)
		condition_evaluators.append(evaluator)
	assert(rules.size() == target_selectors.size())
	assert(rules.size() == condition_evaluators.size())

# TODO: Return BehaviorResult or such.
func choose(action_cooldowns: Dictionary, elapsed_time: float) -> Dictionary:
	# This happened once becaues a single behavior resource was being
	# shared across scene instances. Leaving here just in case.
	if not is_instance_valid(actor):
		assert(false, "Should not happen")
		return {}
	for i in rules.size():
		var rule = rules[i]
		# Check cooldowns.
		if action_cooldowns.has(rule.action.skill_name):
			var can_run_after = action_cooldowns[rule.action.skill_name]
			if elapsed_time < can_run_after:
				continue
		if condition_evaluators[i]:
			if not condition_evaluators[i].evaluate():
				continue
		var action = Action.make_runnable_action(rule.action)
		var target = target_selectors[i].select_target(action, actor, side_component)
		if target.valid():
			return {"id": i, "rule": rule, "target": target, "action": action}
	return {}

func serialize() -> PackedByteArray:
	var data = []
	for rule in rules:
		var rule_dict = {
			"target": rule.target_selection.skill_name,
			"action": rule.action.skill_name,
		}
		data.append(rule_dict)
	return var_to_bytes(data)

static func deserialize(serialized_behavior: PackedByteArray) -> Behavior:
	var behavior = Behavior.new()
	var _data = bytes_to_var(serialized_behavior)
	# TODO: Fix and uncomment when we network again.
	#for serialized_rule in data:
		#var rule = Rule.make(
			#SkillManager.make_target_selection_instance(serialized_rule.target),
			#SkillManager.make_action_instance(serialized_rule.action)
		#)
		#behavior.rules.append(rule)
	return behavior

func _to_string() -> String:
	var result = ""
	for rule in rules:
		result += "%s\n" % str(rule)
	return result
