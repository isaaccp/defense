extends Resource

class_name MilestoneDef

enum EvaluationPhase {
	LEVEL_END,
	RUN_END
}

enum Visibility {
	VISIBLE,
	SECRET,
	HIDDEN_UNTIL_PROGRESS
}

@export var id: StringName
@export var name: String
@export_multiline var description: String
@export var phase: EvaluationPhase
@export var visibility: Visibility = Visibility.VISIBLE
@export var required_count: int = 1
@export var reward_skills: Array[Skill] = []

# Returns the new absolute progress toward this achievement.
func evaluate(current_progress: int, level_stats: AggregateStats, run_stats: AggregateStats, global_stats: AggregateStats) -> int:
	return current_progress
