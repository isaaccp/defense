extends PositionTargetSorter

func compare(pos_a: Vector2, pos_b: Vector2, this_actor: Actor) -> bool:
	var distance_a = this_actor.position.distance_to(pos_a)
	var distance_b = this_actor.position.distance_to(pos_b)
	return distance_a > distance_b
