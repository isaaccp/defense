extends TargetSelector

class_name PositionTargetSelector

var condition_evaluator: PositionConditionEvaluator

func select_target(action: Action, actor: Actor, side_component: SideComponent) -> Target:
	var targets = select_targets(action, actor, side_component)
	if def.sortable:
		assert(def.params.placeholder_set(SkillParams.PlaceholderId.SORT))
		var target_sort = def.params.get_placeholder_value(SkillParams.PlaceholderId.SORT)
		var sorter = SkillManager.make_position_target_sorter(target_sort)
		sorter.sort(actor, targets)
	for target in targets:
		# Verify condition.
		if condition_evaluator and not condition_evaluator.evaluate(target):
			continue
		# Verify in range.
		if action.filter_with_distance:
			if not _check_distance(actor, target, action):
				continue
		# If we didn't check distance earlier, check it on the node
		# that we would return.
		if not action.filter_with_distance:
			if not _check_distance(actor, target, action):
				return Target.make_invalid()
		return Target.make_position_target(target)
	# If we didn't find a target, return invalid.
	return Target.make_invalid()

func _check_distance(actor: Node2D, target: Vector2, action: Action) -> bool:
	var distance = actor.position.distance_to(target)
	return action.min_distance <= distance and distance <= action.max_distance

# Note that we'll select the *first* target that is valid, so order matters.
func select_targets(_action: Action, _actor: Actor, _side_component: SideComponent) -> Array[Vector2]:
	assert(false, "Must be implemented by subclasses")
	return []
