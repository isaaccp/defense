extends TargetSelector

class_name NodeTargetSelector

const TAUNTED_DEF = preload("res://effects/statuses/taunted.tres")

# Conditions are ANDed: a candidate must pass all of them. Empty array = no
# per-candidate filtering.
var condition_evaluators: Array[TargetActorConditionEvaluator] = []

func select_target(action: Action, actor: Actor, side_component: SideComponent) -> Target:
	var targets = select_targets(action, actor, side_component)

	# Taunt intercept.
	var status_comp = Component.get_or_null(actor, StatusComponent.component) as StatusComponent
	if status_comp and status_comp.has_status(TAUNTED_DEF.name):
		var taunt_params = status_comp.get_status_params(TAUNTED_DEF.name) as TauntedParams
		if taunt_params and is_instance_valid(taunt_params.source_actor) and not taunt_params.source_actor.destroyed:
			if targets.has(taunt_params.source_actor):
				var taunt_target = taunt_params.source_actor
				var all_pass := true
				for evaluator in condition_evaluators:
					if not evaluator.evaluate(taunt_target):
						all_pass = false
						break
				if all_pass and _check_distance(actor, taunt_target, action):
					return ConditionalTarget.make_actor_conditional_target(taunt_target, condition_evaluators)
				# If we must target the taunter but they fail conditions or distance, we fail this rule entirely.
				return Target.make_invalid()
	
	if def.sortable:
		var sorter = TargetSorterFactory.make_actor_target_sorter(def.sort())
		sorter.sort(actor, targets)
	for target in targets:
		# Verify all conditions pass.
		var all_pass := true
		for evaluator in condition_evaluators:
			if not evaluator.evaluate(target):
				all_pass = false
				break
		if not all_pass:
			continue
		# Verify in range.
		if action.filter_with_distance:
			if not _check_distance(actor, target, action):
				continue
		# Skip if dead (we may want to allow later through a setting if e.g. we
		# want to be able to resurrect).
		if target.destroyed:
			continue
		# If we didn't check distance earlier, check it on the node
		# that we would return.
		if not action.filter_with_distance:
			if not _check_distance(actor, target, action):
				return Target.make_invalid()
		return ConditionalTarget.make_actor_conditional_target(target, condition_evaluators)
	# If we didn't find a target, return invalid.
	return Target.make_invalid()

func _check_distance(actor: Node2D, target: Node2D, action: Action) -> bool:
	var distance = target.position.distance_to(actor.position)
	return action.min_distance <= distance and distance <= action.max_distance

# Note that we'll select the *first* target that is valid, so order matters.
# Must return an array of Node2D but hard to actually make Godot enforce that
# without pain.
func select_targets(_action: Action, _actor: Actor, _side_component: SideComponent) -> Array[Actor]:
	assert(false, "Must be implemented by subclasses")
	return []
