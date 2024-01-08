extends TargetSorter

class_name PositionTargetSorter

func sort(this_actor: Actor, positions: Array[Vector2]) -> void:
	positions.sort_custom(compare.bind(this_actor))

# Must be implemented by children.
func compare(_pos_a: Vector2, _pos_b: Vector2, _this_actor: Actor) -> bool:
	assert(false, "Must be implemented")
	return false
