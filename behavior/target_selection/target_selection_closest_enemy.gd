extends Object

static func select_target(entity: BehaviorEntity, target_selection_def: TargetSelectionDef) -> Node2D:
	var nodes = null
	if entity.is_in_group("characters"):
		nodes = Global.get_tree().get_nodes_in_group("enemies")
	else:
		nodes = Global.get_tree().get_nodes_in_group("characters")
	var closest = _nearest_node(nodes, entity.position)
	return closest

static func _nearest_node(nodes: Array, location: Vector2):
	var min_distance = -1.0
	var nearest: Node
	for node in nodes:
		var distance = location.distance_squared_to(node.global_position)
		if min_distance < 0 or distance < min_distance:
			nearest = node
			min_distance = distance
	return nearest
