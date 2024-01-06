extends NodeTargetSelector

func select_targets(action: Action, actor: Actor, side_component: SideComponent) -> Array:
	var targets = side_component.enemies()
	_sort_by_distance(targets, actor)
	return targets

static func _sort_by_distance(nodes: Array, actor: Node2D):
	var compare_distance = func(node_a, node_b):
		var distance_a = actor.position.distance_to(node_a.position)
		var distance_b = actor.position.distance_to(node_b.position)
		return distance_a < distance_b  # Closest first

	nodes.sort_custom(compare_distance)
