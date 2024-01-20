extends Resource

class_name LevelProvider

@export_group("Required")
@export var players: int
@export var levels: Array[PackedScene]
@export var available_characters: Array[GameplayCharacter]

@export_group("Storage")
@export var current_level = 0

@export_group("Testing")
# The following two override the settings in the character loaded, leave
# empty except for debugging/testing.
# Unlocked skills on start.
@export var unlocked_skills: SkillTreeState
# Initial behavior for characters.
@export var behavior: StoredBehavior = StoredBehavior.new()

func reset():
	current_level = 0

func advance() -> bool:
	if is_last_level():
		return false
	current_level += 1
	return true

func load_level() -> PackedScene:
	return levels[current_level]

func is_last_level():
	return current_level + 1 == levels.size()

# For testing.
func set_from(other: LevelProvider):
	players = other.players
	levels = other.levels
	available_characters = other.available_characters
	unlocked_skills = other.unlocked_skills
	behavior = other.behavior
