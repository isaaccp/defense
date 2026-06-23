extends MilestoneDef
class_name LevelsBeatenInRunRepeatedMilestone

@export var levels_in_run: int = 3

func evaluate(current_progress: int, _level_stats: AggregateStats, run_stats: AggregateStats, _global_stats: AggregateStats) -> int:
	if phase != MilestoneDef.EvaluationPhase.RUN_END or not run_stats:
		return current_progress
	if run_stats.get_value(Stat.LevelsBeaten) >= levels_in_run:
		return current_progress + 1
	return current_progress
