extends Resource

class_name LevelProvider

@export var players: int
@export var levels: Array[PackedScene]

# Unlocked skills on start.
@export var skill_unlock_state: SkillUnlockState

var current_level = -1

func next_level() -> PackedScene:
	current_level += 1
	if current_level >= levels.size():
		return null
	return levels[current_level]
