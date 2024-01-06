extends TargetSorter

class_name ActorTargetSorter

# Actors must be of type Array[Actor], but don't want to handle
# casting everywhere else. Maybe do that later :)
func sort(this_actor: Actor, actors: Array) -> void:
	actors.sort_custom(compare.bind(this_actor))

# Must be implemented by children.
func compare(actor_a: Actor, actor_b: Actor, this_actor: Actor) -> bool:
	assert(false, "Must be implemented")
	return false
