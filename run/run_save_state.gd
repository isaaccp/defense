extends Resource

class_name RunSaveState

@export var gameplay_characters: Array[GameplayCharacter]
@export var level_provider: LevelProvider
# TODO: Uncomment once a Resource and remove member Stats from Run.
#@export var stats: Stats

static func make(gameplay_characters: Array[GameplayCharacter], level_provider: LevelProvider) -> RunSaveState:
	var run_save_state = RunSaveState.new()
	run_save_state.gameplay_characters = gameplay_characters
	run_save_state.level_provider = level_provider
	return run_save_state
