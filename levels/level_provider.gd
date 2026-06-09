extends Resource

class_name LevelProvider

@export_group("Required")
@export var players: int
## The level catalog. Grouped by `Level.difficulty` into a difficulty-band
## pool at load time; the run picks one from the matching pool per stage.
@export var levels: Array[PackedScene]
@export var available_characters: Array[GameplayCharacter]
@export var relic_library: RelicLibrary
## Reward types available at reward stages. The run picks one per stage
## (currently uniformly at random from the pool).
@export var available_rewards: Array[RewardDef]

@export_group("Testing")
# The following two override the settings in the character loaded, leave
# empty except for debugging/testing.
# Unlocked skills on start.
@export var unlocked_skills: SkillTreeState
# Initial behavior for characters.
@export var behavior: StoredBehavior = StoredBehavior.new()

var _levels_by_difficulty: Dictionary = {}
var _index_built: bool = false

func _build_index() -> void:
	_levels_by_difficulty.clear()
	for scene in levels:
		var lvl := scene.instantiate() as Level
		var d := lvl.difficulty
		lvl.queue_free()
		if not _levels_by_difficulty.has(d):
			_levels_by_difficulty[d] = [] as Array[PackedScene]
		(_levels_by_difficulty[d] as Array[PackedScene]).append(scene)
	_index_built = true

func _ensure_index() -> void:
	if not _index_built:
		_build_index()

func levels_at_difficulty(d: int) -> Array[PackedScene]:
	_ensure_index()
	return _levels_by_difficulty.get(d, [] as Array[PackedScene])

func has_levels_at_difficulty(d: int) -> bool:
	return not levels_at_difficulty(d).is_empty()

# For testing.
func set_from(other: LevelProvider):
	players = other.players
	levels = other.levels
	available_characters = other.available_characters
	available_rewards = other.available_rewards
	relic_library = other.relic_library
	unlocked_skills = other.unlocked_skills
	behavior = other.behavior
