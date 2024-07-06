extends Resource

class_name RunSaveState

# TODO: As of now this ends up saving all the character scene,
# including animations, etc. Find a way to avoid that.
@export var gameplay_characters: Array[GameplayCharacter]
@export var level_provider: LevelProvider
@export var relic_library: RelicLibrary
@export var stats: Stats

static func make(gameplay_characters: Array[GameplayCharacter], level_provider: LevelProvider) -> RunSaveState:
	var run_save_state = RunSaveState.new()
	run_save_state.gameplay_characters = gameplay_characters
	run_save_state.level_provider = level_provider
	# If it needs to be customized per game_mode or similar, move load somewhere else
	# and pass it as a parameter.
	run_save_state.relic_library = preload("res://effects/relics/relic_library.tres")
	run_save_state.stats = Stats.new()
	return run_save_state
