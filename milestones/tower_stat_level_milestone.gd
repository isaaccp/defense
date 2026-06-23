extends MilestoneDef

class_name TowerStatLevelMilestone

@export var stat_name: StringName
@export var target_value: int = 0

func _init():
	phase = EvaluationPhase.LEVEL_END

func evaluate(current_progress: int, level_stats: AggregateStats, _run_stats: AggregateStats, _global_stats: AggregateStats) -> int:
	if level_stats.tower_stats.get_value(stat_name) == target_value:
		return current_progress + 1
	return current_progress
