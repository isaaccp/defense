extends MilestoneDef

class_name LevelsBeatenMilestone

func evaluate(_current_progress: int, _level_stats: AggregateStats, run_stats: AggregateStats, global_stats: AggregateStats) -> int:
	var total_beaten = global_stats.get_value(Stat.LevelsBeaten)
	if run_stats:
		total_beaten += run_stats.get_value(Stat.LevelsBeaten)
	return total_beaten
