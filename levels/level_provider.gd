extends Resource

class_name LevelProvider

@export var players: int
@export var levels: Array[PackedScene]

# Unlocked skills on start.
@export var skill_tree_state: SkillTreeState

# Initial behavior for characters.
@export var behavior: Behavior = Behavior.new()

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
	skill_tree_state = other.skill_tree_state
	behavior = other.behavior
