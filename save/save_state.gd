extends Resource

class_name SaveState

# State independent from current run.
# Eventually this should include unlocked skill tree, etc.
@export var behavior_library: BehaviorLibrary

# Run state.
# E.g. current level, current acquired skill tree, etc.
