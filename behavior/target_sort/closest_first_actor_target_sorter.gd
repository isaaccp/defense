extends ActorTargetSorter

class_name ClosestFirstActorTargetSorter

func sort(this: Actor, actors: Array) -> void:
	_sort_by_distance(this, actors)

static func _sort_by_distance(this: Actor, nodes: Array):
	var compare_distance = func(node_a, node_b):
		var distance_a = this.position.distance_to(node_a.position)
		var distance_b = this.position.distance_to(node_b.position)
		return distance_a < distance_b  # Closest first

	nodes.sort_custom(compare_distance)
