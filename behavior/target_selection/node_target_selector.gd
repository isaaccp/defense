extends TargetSelector

class_name NodeTargetSelector

var condition_evaluator: TargetNodeConditionEvaluator

func select_target(action: Action, body: CharacterBody2D, side_component: SideComponent) -> Target:
	var targets = select_targets(action, body, side_component)
	for target in targets:
		# Verify condition.
		if condition_evaluator and not condition_evaluator.evaluate(target):
			continue
		# Verify in range.
		if action.filter_with_distance:
			if not _check_distance(body, target, action):
				continue
		# Skip if dead (we may want to allow later through a setting if e.g. we
		# want to be able to resurrect).
		var health_component = Component.get_or_null(target, HealthComponent.component)
		if health_component and health_component.is_dead:
			continue
		# If we didn't check distance earlier, check it on the node
		# that we would return.
		if not action.filter_with_distance:
			if not _check_distance(body, target, action):
				return Target.make_invalid()
		return Target.make_actor_target(target)
	# If we didn't find a target, return invalid.
	return Target.make_invalid()

func _check_distance(body: Node2D, target: Node2D, action: Action) -> bool:
	var distance = target.position.distance_to(body.position)
	return action.min_distance <= distance and distance <= action.max_distance

# Note that we'll select the *first* target that is valid, so order matters.
# Must return an array of Node2D but hard to actually make Godot enforce that
# without pain.
func select_targets(action: Action, body: CharacterBody2D, side_component: SideComponent) -> Array:
	assert(false, "Must be implemented by subclasses")
	return []
