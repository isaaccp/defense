@tool
extends Resource

class_name Behavior

@export var saved_rules: Array[RuleDef]
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

# When behavior is set through editor/etc, we don't write (well, we do for now,
# but we want to change it) the full skill definition, but just RuleSkillDefs.
# From there we can create the full instance using the SkillManager.
func restore():
	rules.clear()
	for saved_rule in saved_rules:
		var rule = SkillManager.restore_rule(saved_rule)
		rules.append(rule)

func prepare(actor_: Actor, side_component_: SideComponent):
	restore()
	actor = actor_
	side_component = side_component_
	target_selectors.clear()
	condition_evaluators.clear()
	for rule in rules:
		var evaluator: ConditionEvaluator = null
		var target_node_evaluator: TargetActorConditionEvaluator = null
		var position_evaluator: PositionConditionEvaluator = null
		var target_selector: TargetSelector = null
		match rule.condition.type:
			ConditionDef.Type.ANY:
				evaluator = SkillManager.make_any_condition_evaluator(rule.condition)
			ConditionDef.Type.SELF:
				evaluator = SkillManager.make_self_condition_evaluator(rule.condition, actor)
			ConditionDef.Type.GLOBAL:
				# TODO: Implement.
				pass
			ConditionDef.Type.TARGET_ACTOR:
				target_node_evaluator = SkillManager.make_target_actor_condition_evaluator(rule.condition, actor)
			ConditionDef.Type.TARGET_POSITION:
				position_evaluator = SkillManager.make_position_condition_evaluator(rule.condition, actor)
		match rule.target_selection.type:
			Target.Type.ACTOR:
				target_selector = SkillManager.make_actor_target_selector(rule.target_selection, target_node_evaluator)
			Target.Type.POSITION:
				target_selector = SkillManager.make_position_target_selector(rule.target_selection, position_evaluator)
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
		if action_cooldowns.has(rule.action.id):
			var can_run_after = action_cooldowns[rule.action.id]
			if elapsed_time < can_run_after:
				continue
		if condition_evaluators[i]:
			if not condition_evaluators[i].evaluate():
				continue
		var action = SkillManager.make_runnable_action(rule.action)
		var target = target_selectors[i].select_target(action, actor, side_component)
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
