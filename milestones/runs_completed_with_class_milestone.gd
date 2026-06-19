extends MilestoneDef

class_name RunsCompletedWithClassMilestone

@export var required_classes: Array[Enum.CharacterSceneId]

func evaluate(_level_stats: AggregateStats, _run_stats: AggregateStats, global_stats: AggregateStats) -> int:
	for class_id in required_classes:
		if not global_stats.character_stats.has(class_id):
			return 0
		var wins = global_stats.character_stats[class_id].get_value(Stat.RunsCompleted)
		if wins < required_count:
			return 0
	return required_count
