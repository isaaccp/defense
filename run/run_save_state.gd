extends Resource

class_name RunSaveState

# TODO: As of now this ends up saving all the character scene,
# including animations, etc. Find a way to avoid that.
@export var gameplay_characters: Array[GameplayCharacter]
@export var level_provider: LevelProvider
@export var current_level: int
@export var relic_library_state: RelicLibraryState
@export var stats: Stats

static func make(gameplay_characters: Array[GameplayCharacter], level_provider: LevelProvider) -> RunSaveState:
	var run_save_state = RunSaveState.new()
	run_save_state.gameplay_characters = gameplay_characters
	run_save_state.level_provider = level_provider
	run_save_state.current_level = 0
	run_save_state.relic_library_state = RelicLibraryState.from_relic_library(level_provider.relic_library)
	run_save_state.stats = Stats.new()
	return run_save_state
