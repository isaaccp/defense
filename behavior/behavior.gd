@tool
extends Resource

class_name Behavior

var rules: Array[Rule]
var actor: Actor
var side_component: SideComponent
var vitals_component: VitalsComponent

# TODO: Consider also preparing action if needed.
# It would allow to do things like "every time you use this action, it
# does extra damage", which is neat, with the caveat that likely for
# actions we would like to share across rules, unlike for the other ones,
# i.e., instead of an Array a Dictionary by action.id.
var target_selectors: Array[TargetSelector] = []
# Per-rule list of ANY/SELF/GLOBAL condition evaluators (each rule may have
# multiple, all ANDed). TARGET_ACTOR/TARGET_POSITION conditions are handled
# by the target selector itself, not here.
var pre_selection_evaluators: Array = []

static func restore(stored_behavior: StoredBehavior) -> Behavior:
	var behavior = Behavior.new()
	for stored_rule in stored_behavior.stored_rules:
		var rule = SkillManager.restore_rule(stored_rule)
		behavior.rules.append(rule)
	return behavior

func prepare(actor_: Actor, side_component_: SideComponent, vitals_component_: VitalsComponent):
	actor = actor_
	side_component = side_component_
	vitals_component = vitals_component_
	target_selectors.clear()
	pre_selection_evaluators.clear()
	for rule in rules:
		var conds = rule.effective_conditions()
		# Bucket conditions by type. ANY/SELF/GLOBAL gate the rule before
		# target selection; TARGET_ACTOR/TARGET_POSITION are handed to the
		# target selector to filter candidates with.
		var pre_sel: Array[ConditionEvaluator] = []
		var target_actor_evals: Array[TargetActorConditionEvaluator] = []
		var target_pos_evals: Array[PositionConditionEvaluator] = []
		for cond in conds:
			match cond.type:
				ConditionDef.Type.ANY:
					pre_sel.append(ConditionEvaluatorFactory.make_any_condition_evaluator(cond))
				ConditionDef.Type.SELF:
					pre_sel.append(ConditionEvaluatorFactory.make_self_condition_evaluator(cond, actor))
				ConditionDef.Type.GLOBAL:
					# TODO: Implement.
					pass
				ConditionDef.Type.TARGET_ACTOR, ConditionDef.Type.TARGET_POSITION:
					match rule.target_selection.type:
						Target.Type.SELF, Target.Type.ACTOR:
							target_actor_evals.append(ConditionEvaluatorFactory.make_target_actor_condition_evaluator(cond, actor))
						Target.Type.POSITION:
							if cond.type == ConditionDef.Type.TARGET_POSITION:
								target_pos_evals.append(ConditionEvaluatorFactory.make_position_condition_evaluator(cond, actor))
							else:
								push_error("Rule with POSITION target has TARGET_ACTOR condition '%s' — incompatible" % cond.name())
		var target_selector: TargetSelector = null
		match rule.target_selection.type:
			Target.Type.SELF, Target.Type.ACTOR:
				target_selector = TargetSelectorFactory.make_actor_target_selector(rule.target_selection, target_actor_evals)
			Target.Type.POSITION:
				target_selector = TargetSelectorFactory.make_position_target_selector(rule.target_selection, target_pos_evals)
		target_selectors.append(target_selector)
		pre_selection_evaluators.append(pre_sel)
	if rules.size() != target_selectors.size() or rules.size() != pre_selection_evaluators.size():
		push_error("Behavior array size mismatch: rules=%d selectors=%d pre_sel=%d" % [
			rules.size(), target_selectors.size(), pre_selection_evaluators.size()
		])
		return

# TODO: Return BehaviorResult or such.
func choose(action_cooldowns: Dictionary, elapsed_time: float) -> Dictionary:
	# This happened once becaues a single behavior resource was being
	# shared across scene instances. Leaving here just in case.
	if not is_instance_valid(actor):
		push_error("Behavior.choose() called with invalid actor")
		return {}
	for i in rules.size():
		var rule = rules[i]
		# Check cooldowns.
		if action_cooldowns.has(rule.action.skill_name):
			var can_run_after = action_cooldowns[rule.action.skill_name]
			if elapsed_time < can_run_after:
				continue
		# Instantiate the action first so conditions (and the selector below)
		# can read action-level params like max_distance / aoe_shape. Action
		# instantiation is a single script .new() — sub-microsecond.
		var action = Action.make_runnable_action(rule.action)
		if action.focus_cost > 0:
			var current_focus = vitals_component.get_vital_current(VitalsComponent.VitalType.FOCUS)
			if action.focus_cost > current_focus:
				continue
		var all_pass = true
		for evaluator in pre_selection_evaluators[i]:
			evaluator.action = action
			evaluator.side_component = side_component
			if not evaluator.evaluate():
				all_pass = false
				break
		if not all_pass:
			continue
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
