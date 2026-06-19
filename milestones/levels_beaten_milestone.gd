extends MilestoneDef

class_name LevelsBeatenMilestone

func evaluate(_level_stats: AggregateStats, _run_stats: AggregateStats, global_stats: AggregateStats) -> int:
	var total_beaten = global_stats.get_value(Stat.LevelsBeaten)
	if total_beaten >= required_count:
		return required_count
	return 0
