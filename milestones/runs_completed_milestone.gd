extends MilestoneDef

class_name RunsCompletedMilestone

func evaluate(_current_progress: int, _level_stats: AggregateStats, run_stats: AggregateStats, global_stats: AggregateStats) -> int:
	var total_completed = global_stats.get_value(Stat.RunsCompleted)
	if run_stats:
		total_completed += run_stats.get_value(Stat.RunsCompleted)
	return total_completed
