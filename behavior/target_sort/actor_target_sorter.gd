extends TargetSorter

class_name ActorTargetSorter


# actors must be of type Array[Actor], but don't want to handle
# casting everywhere else. Maybe do that later :)
func sort(this: Actor, actors: Array) -> void:
	assert(false, "Must be implemented")
