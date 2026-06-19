extends Resource

class_name LevelProvider

@export_group("Required")
@export var players: int
## How many fight stages this run has. Each stage's difficulty equals its
## index (stage 1 → d=1). Validated against `levels` at run start.
@export var total_stages: int = 1
## The level catalog. Grouped by `Level.difficulty` into a difficulty-band
## pool at load time; the run picks one from the matching pool per stage.
@export var levels: Array[PackedScene]
@export var available_characters: Array[GameplayCharacter]
## Skills that are automatically unlocked at the start of a new save (e.g. starter classes)
@export var starting_unlocked_skills: Array[Skill]
@export var relic_library: RelicLibrary
@export var milestone_library: MilestoneLibrary
## Reward types available at reward stages. The run picks 2 different
## types per stage (currently uniformly at random from the pool).
@export var available_rewards: Array[RewardDef]

@export_group("Testing")
# The following two override the settings in the character loaded, leave
# empty except for debugging/testing.
# Unlocked skills on start.
@export var unlocked_skills: SkillTreeState
# Initial behavior for characters.
@export var behavior: StoredBehavior = StoredBehavior.new()

# How many distinct reward types we offer at each stage. Currently fixed,
# but lifted out as a constant so the schedule generation doesn't have a
# magic number sprinkled through it.
const SETS_PER_STAGE: int = 2

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

## Returns "" if the provider can support a full run, or a human-readable
## error describing the first problem found. Hard-asserted by RunSaveState.make.
func validate_runnable() -> String:
	if total_stages < 1:
		return "total_stages must be >= 1 (got %d)" % total_stages
	for stage in range(1, total_stages + 1):
		if not has_levels_at_difficulty(stage):
			return "no level registered at difficulty %d" % stage
	if available_rewards.is_empty():
		return "available_rewards is empty"
	# Starting-kit relics on each character must be class_relic so they
	# don't also appear in the random draft pool. Catches the easy mistake
	# of giving a class a "general" relic at run start.
	if relic_library:
		for gc in available_characters:
			for relic_name in gc.relics:
				var relic := relic_library.get_relic(relic_name)
				if relic == null:
					return "%s starts with unknown relic %s" % [gc.name, relic_name]
				if not relic.class_relic:
					return "%s starts with %s, which is not marked class_relic" % [gc.name, relic_name]
	return ""

# For testing.
func set_from(other: LevelProvider):
	players = other.players
	total_stages = other.total_stages
	levels = other.levels
	available_characters = other.available_characters
	available_rewards = other.available_rewards
	relic_library = other.relic_library
	unlocked_skills = other.unlocked_skills
	behavior = other.behavior
