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
		var max_distance_squared = action.max_distance * action.max_distance
		var min_distance_squared = action.min_distance * action.min_distance
		var distance_squared = target.position.distance_squared_to(body.position)
		if not (min_distance_squared <= distance_squared and distance_squared <= max_distance_squared):
			continue
		# Skip if dead (we may want to allow later through a setting if e.g. we
		# want to be able to resurrect).
		var health_component = Component.get_or_null(target, HealthComponent.component)
		if health_component and health_component.is_dead:
			continue
		return Target.make_node_target(target)
	# If we didn't find a target, return invalid.
	return Target.make_invalid()

# Note that we'll select the *first* target that is valid, so order matters.
# Must return an array of Node2D but hard to actually make Godot enforce that
# without pain.
func select_targets(action: Action, body: CharacterBody2D, side_component: SideComponent) -> Array:
	assert(false, "Must be implemented by subclasses")
	return []
