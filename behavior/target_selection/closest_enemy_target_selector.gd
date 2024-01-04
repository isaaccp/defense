extends NodeTargetSelector

func select_targets(action: Action, body: CharacterBody2D, side_component: SideComponent) -> Array:
	var max_distance_squared = action.max_distance * action.max_distance
	var min_distance_squared = action.min_distance * action.min_distance
	var targets = side_component.enemies()
	_sort_by_distance(targets, body)
	return targets

static func _sort_by_distance(nodes: Array, body: Node2D):
	var compare_distance = func(node_a, node_b):
		var distance_a = body.position.distance_to(node_a.position)
		var distance_b = body.position.distance_to(node_b.position)
		return distance_a < distance_b  # Closest first

	nodes.sort_custom(compare_distance)
