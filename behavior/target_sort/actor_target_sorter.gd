extends TargetSorter

class_name ActorTargetSorter

func sort(this_actor: Actor, actors: Array[Actor]) -> void:
	actors.sort_custom(compare.bind(this_actor))

# Must be implemented by children.
func compare(_actor_a: Actor, _actor_b: Actor, _this_actor: Actor) -> bool:
	assert(false, "Must be implemented")
	return false
