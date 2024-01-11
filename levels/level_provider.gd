extends Resource

class_name LevelProvider

@export var players: int
@export var levels: Array[PackedScene]
@export var available_characters: Array[GameplayCharacter]


@export_group("Testing")
# The following two override the settings in the character loaded, leave
# empty except for debugging/testing.
# Unlocked skills on start.
@export var skill_tree_state: SkillTreeState
# Initial behavior for characters.
@export var behavior: StoredBehavior = StoredBehavior.new()

var current_level = -1

func next_level() -> PackedScene:
	if last_level():
		return null
	current_level += 1
	return levels[current_level]

func last_level():
	return current_level + 1 == levels.size()

# For testing.
func set_from(other: LevelProvider):
	players = other.players
	levels = other.levels
	available_characters = other.available_characters
	skill_tree_state = other.skill_tree_state
	behavior = other.behavior
