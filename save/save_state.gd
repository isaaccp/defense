extends Resource

class_name SaveState

# State independent from current run.
# Eventually this should include unlocked skill tree, etc.
@export var behavior_library: BehaviorLibrary
# If needed later, keep one of those per game-mode.
@export var unlocked_skills: SkillTreeState

# Run state.
# E.g. current level, current acquired skill tree, etc.
@export var run_save_state: RunSaveState
