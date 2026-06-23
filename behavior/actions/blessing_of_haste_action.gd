extends SpawnAtTargetNodePositionAction

const haste_scene = preload("res://behavior/actions/scenes/blessing_of_haste.tscn")

func _init():
	spawn_scene = haste_scene
	prepare_time = 0.3
	duration = 0.5
	cooldown = 10.0
	max_distance = 200
	focus_cost = 4

func description():
	return "Grants Hasted to an ally, increasing speed and reducing cooldowns for 6s"
