extends Object

static func select_target(entity: BehaviorEntity, action: Action, target_selection_def: TargetSelectionDef) -> Node2D:
	return _nearest_node(entity.enemies(), entity.position, func(node: Node2D):
		var distance = action.distance
		return distance < 0 or node.position.distance_to(entity.position) < distance
	)

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
