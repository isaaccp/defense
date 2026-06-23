extends MilestoneDef

class_name StatMilestone

@export var stat_name: StringName

func evaluate(current_progress: int, _level_stats: AggregateStats, _run_stats: AggregateStats, global_stats: AggregateStats) -> int:
	return global_stats.aggregate.get_value(stat_name)
