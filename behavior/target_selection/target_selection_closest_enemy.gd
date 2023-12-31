extends Object

static func select_target(body: CharacterBody2D, side_component: SideComponent, action: Action, target_selection_def: TargetSelectionDef) -> Target:
	var nearest_node = _nearest_node(side_component.enemies(), body.position, func(node: Node2D):
		var health_component = Component.get_or_null(node, HealthComponent.component)
		if health_component and health_component.is_dead:
			return false
		var distance = action.distance
		return distance < 0 or node.position.distance_to(body.position) < distance
	)
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
