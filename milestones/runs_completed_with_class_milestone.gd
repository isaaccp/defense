extends MilestoneDef

class_name RunsCompletedWithClassMilestone

@export var required_classes: Array[Enum.CharacterSceneId]

func evaluate(current_progress: int, _level_stats: AggregateStats, run_stats: AggregateStats, _global_stats: AggregateStats) -> int:
	if not run_stats:
		return current_progress
	for class_id in required_classes:
		if not run_stats.character_stats.has(class_id):
			return current_progress
		var wins = run_stats.character_stats[class_id].get_value(Stat.RunsCompleted)
		if wins == 0:
			return current_progress
	return current_progress + 1
