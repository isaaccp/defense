extends Resource

class_name LevelProvider

@export_group("Required")
@export var players: int
@export var levels: Array[PackedScene]
@export var available_characters: Array[GameplayCharacter]
@export var relic_library: RelicLibrary

@export_group("Testing")
# The following two override the settings in the character loaded, leave
# empty except for debugging/testing.
# Unlocked skills on start.
@export var unlocked_skills: SkillTreeState
# Initial behavior for characters.
@export var behavior: StoredBehavior = StoredBehavior.new()

func load_level(current_level: int) -> PackedScene:
	return levels[current_level]

func is_last_level(current_level: int):
	return current_level + 1 == levels.size()

# TODO: Do something better, maybe :)
func are_relics_available(current_level):
	if not relic_library:
		return false
	return (current_level % 2) == 1

# For testing.
func set_from(other: LevelProvider):
	players = other.players
	levels = other.levels
	available_characters = other.available_characters
	unlocked_skills = other.unlocked_skills
	behavior = other.behavior
