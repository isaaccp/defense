extends SpawnAtTargetNodePositionAction

const fan_scene = preload("res://behavior/actions/scenes/fan_of_knives.tscn")

func _init():
	spawn_scene = fan_scene
	prepare_time = 0.2
	duration = 0.4
	cooldown = 6.0
	max_distance = 150
	focus_cost = 3

func description():
	return "Throws daggers in all directions dealing minor damage"
