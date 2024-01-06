extends ActorTargetSorter

class_name PositionToActorTargetSorterAdapter

var sorter: PositionTargetSorter

func _init(position_target_sorter: PositionTargetSorter):
	sorter = position_target_sorter

func compare(actor_a: Actor, actor_b: Actor, this_actor: Actor) -> bool:
	return sorter.compare(actor_a.position, actor_b.position, this_actor)
