extends SpawnAtTargetNodePositionAction

const heal_effect_scene = preload("res://behavior/actions/scenes/heal.tscn")

# TODO: Look into turning stuff like this into a resource.

func _init():
	spawn_scene = heal_effect_scene
	duration = 0.5
	prepare_time = 0.5
	cooldown = 5.0
	max_distance = 200
