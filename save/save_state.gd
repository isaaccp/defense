extends Resource

class_name SaveState

# State independent from current run.
# Eventually this should include unlocked skill tree, etc.
@export var behavior_library: BehaviorLibrary
# If needed later, keep one of those per game-mode.
@export var unlocked_skills: SkillTreeState
# XP used to unlock skills, granted at end of run.
@export var meta_xp: int
# Set initially to skip the "PRE_RUN" section on first run.
@export var first_run = true
# Run state.
# E.g. current level, current acquired skill tree, etc.
@export var run_save_state: RunSaveState

static func make_new() -> SaveState:
	var save_state = SaveState.new()
	save_state.behavior_library = BehaviorLibrary.new()
	save_state.unlocked_skills = SkillTreeState.new()
	save_state.unlocked_skills.add_skill_names(Constants.base_acquired_skills)

	return save_state
