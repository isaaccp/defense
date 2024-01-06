extends TargetSorter

class_name PositionTargetSorter

func sort(this_actor: Actor, positions: Array[Vector2]) -> void:
	positions.sort_custom(compare.bind(this_actor))

# Must be implemented by children.
func compare(pos_a: Vector2, pos_b: Vector2, this_actor: Actor) -> bool:
	assert(false, "Must be implemented")
	return false
