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
@export var stats: Stats
## Shared between all characters. Earned from chests, spent at shops.
@export var gold: int = 0

static func make(gameplay_characters: Array[GameplayCharacter], level_provider: LevelProvider) -> RunSaveState:
	var run_save_state = RunSaveState.new()
	run_save_state.gameplay_characters = gameplay_characters
	run_save_state.level_provider = level_provider
	run_save_state.current_stage = 1
	run_save_state.current_phase = Phase.FIGHT
	run_save_state.relic_library_state = RelicLibraryState.from_relic_library(level_provider.relic_library)
	run_save_state.stats = Stats.new()
	return run_save_state

func clone() -> RunSaveState:
	return duplicate_deep() as RunSaveState
