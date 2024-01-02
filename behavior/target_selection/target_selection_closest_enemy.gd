extends Object

static func select_target(target_selection_def: TargetSelectionDef, evaluator: TargetNodeConditionEvaluator, action: Action, body: CharacterBody2D, side_component: SideComponent) -> Target:
	var max_distance_squared = action.max_distance * action.max_distance
	var min_distance_squared = action.min_distance * action.min_distance
	var nearest_node = _nearest_node(side_component.enemies(), body.position, func(node: Node2D):
		if evaluator and not evaluator.evaluate(node):
			return false
		var health_component = Component.get_or_null(node, HealthComponent.component)
		if health_component and health_component.is_dead:
			return false
		var distance_squared = node.position.distance_squared_to(body.position)
		return min_distance_squared < distance_squared and distance_squared < max_distance_squared
	)
	# nearest_node may be null, but that's fine as it'll make the Target
	# invalid. Alternatively we could check for null and return
	# Target.make_invalid() instead.
	return Target.make_node_target(nearest_node)

static func _nearest_node(nodes: Array, location: Vector2, filter: Callable = func(node: Node2D): return true):
	var min_distance = -1.0
	var nearest: Node
	for node in nodes:
		if not filter.call(node):
			continue
		var distance = location.distance_squared_to(node.global_position)
		if min_distance < 0 or distance < min_distance:
			nearest = node
			min_distance = distance
	return nearest
