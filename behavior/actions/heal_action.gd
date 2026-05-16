extends SpawnAtTargetNodePositionAction

const heal_effect_scene = preload("res://behavior/actions/scenes/heal.tscn")

# TODO: Look into turning stuff like this into a resource.

func _init():
	spawn_scene = heal_effect_scene
	duration = 0.5
	prepare_time = 0.5
	cooldown = 3.0
	max_distance = 200
	focus_cost = 2

func description() -> String:
	return "Heals the target for 15 hit points"
