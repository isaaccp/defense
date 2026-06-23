extends MilestoneDef

class_name ClassStatMilestone

@export var stat_name: StringName
@export var character_scene_id: Enum.CharacterSceneId

func evaluate(current_progress: int, _level_stats: AggregateStats, _run_stats: AggregateStats, global_stats: AggregateStats) -> int:
	if not global_stats.character_stats.has(character_scene_id):
		return current_progress
	return global_stats.character_stats[character_scene_id].get_value(stat_name)
