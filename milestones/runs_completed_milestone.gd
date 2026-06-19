extends MilestoneDef

class_name RunsCompletedMilestone

func evaluate(_level_stats: AggregateStats, _run_stats: AggregateStats, global_stats: AggregateStats) -> int:
	var total_completed = global_stats.get_value(Stat.RunsCompleted)
	if total_completed >= required_count:
		return required_count
	return 0
