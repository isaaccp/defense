extends Resource

class_name RunSaveState

enum Phase {
	FIGHT,
	REWARD,
}

# TODO: As of now this ends up saving all the character scene,
# including animations, etc. Find a way to avoid that.
@export var gameplay_characters: Array[GameplayCharacter]
@export var level_provider: LevelProvider
## 1-indexed. Also the difficulty of the upcoming fight (or the one whose
## reward is currently being shown), since difficulty = current_stage.
@export var current_stage: int = 1
@export var current_phase: Phase = Phase.FIGHT
@export var relic_library_state: RelicLibraryState
@export var stats: AggregateStats
## Shared between all characters. Earned from chests, spent at shops.
@export var gold: int = 0
## The index of the path chosen on the map screen (0 or 1). -1 if no path chosen yet.
@export var reward_path_chosen: int = -1
## Indices of nodes on the chosen path that have been claimed.
@export var reward_nodes_claimed: Array[int] = []
## Run-wide RNG seed. Used for level pool picks and the reward schedule.
@export var seed: int = 0
## Pre-generated reward schedule, one StageRewards per stage. Built at
## `make()` time so saves restore the exact same offers.
@export var reward_schedule: Array[StageRewards]
@export var unlocked_milestones: Dictionary
@export var unlocked_skills: SkillTreeState
@export var starting_milestone_progress: Dictionary[StringName, int]

static func make(gameplay_characters: Array[GameplayCharacter], level_provider: LevelProvider, unlocked_skills: SkillTreeState, unlocked_milestones: Dictionary, starting_milestone_progress: Dictionary) -> RunSaveState:
	var err := level_provider.validate_runnable()
	if not err.is_empty():
		push_error("LevelProvider is not runnable: %s" % err)
		assert(false, "LevelProvider is not runnable: %s" % err)
	var run_save_state = RunSaveState.new()
	run_save_state.gameplay_characters = gameplay_characters
	run_save_state.level_provider = level_provider
	run_save_state.current_stage = 1
	run_save_state.current_phase = Phase.FIGHT
	run_save_state.relic_library_state = RelicLibraryState.from_relic_library(level_provider.relic_library)
	run_save_state.stats = AggregateStats.new()
	run_save_state.seed = _make_seed()
	run_save_state.unlocked_milestones = unlocked_milestones
	run_save_state.unlocked_skills = unlocked_skills
	# Deep-copy the progress so mid-run evaluation mutations don't alter the snapshot
	run_save_state.starting_milestone_progress = starting_milestone_progress.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	run_save_state.reward_schedule = _generate_schedule(run_save_state, level_provider, unlocked_skills)
	return run_save_state

static func _make_seed() -> int:
	# Non-cryptographic but distinct per run.
	return Time.get_ticks_usec() ^ (randi() << 16)

static func _generate_schedule(rss: RunSaveState, level_provider: LevelProvider, unlocked_skills: SkillTreeState) -> Array[StageRewards]:
	var schedule: Array[StageRewards] = []
	for stage in range(1, level_provider.total_stages + 1):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("%d:%d:schedule" % [rss.seed, stage])
		var stage_rewards := StageRewards.new()
		var required_total = level_provider.SETS_PER_STAGE * level_provider.REWARDS_PER_PATH
		var chosen_templates: Array[RewardDef] = []
		var pool := level_provider.available_rewards.duplicate()
		pool.shuffle()
		for i in range(required_total):
			if pool.is_empty():
				pool = level_provider.available_rewards.duplicate()
				pool.shuffle()
			chosen_templates.append(pool.pop_front())
			
		for set_idx in range(level_provider.SETS_PER_STAGE):
			var reward_set := RewardSet.new()
			var rewards: Array[RewardDef] = []
			for node_idx in range(level_provider.REWARDS_PER_PATH):
				var tmpl = chosen_templates[node_idx * level_provider.SETS_PER_STAGE + set_idx]
				rewards.append(tmpl.roll(rng, rss.relic_library_state, level_provider.relic_library, unlocked_skills))
			reward_set.rewards = rewards
			stage_rewards.sets.append(reward_set)
		schedule.append(stage_rewards)
	return schedule

func clone() -> RunSaveState:
	return duplicate_deep() as RunSaveState
