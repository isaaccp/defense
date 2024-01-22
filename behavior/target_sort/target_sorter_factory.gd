extends Object

class_name TargetSorterFactory

static func make_actor_target_sorter(target_sort: TargetSort) -> ActorTargetSorter:
	assert(target_sort.type in [TargetSort.Type.ACTOR, TargetSort.Type.POSITION])
	var sorter: ActorTargetSorter
	if target_sort.type == TargetSort.Type.ACTOR:
		sorter = target_sort.sorter_script.new() as ActorTargetSorter
	else:
		var position_sorter = make_position_target_sorter(target_sort)
		sorter = PositionToActorTargetSorterAdapter.new(position_sorter)
	sorter.def = target_sort
	return sorter

static func make_position_target_sorter(target_sort: TargetSort) -> PositionTargetSorter:
	assert(target_sort.type in [TargetSort.Type.POSITION])
	var sorter = target_sort.sorter_script.new() as PositionTargetSorter
	sorter.def = target_sort
	return sorter
