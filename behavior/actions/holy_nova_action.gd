extends SpawnAtTargetNodePositionAction

const holy_nova_scene = preload("res://behavior/actions/scenes/holy_nova.tscn")

func _init():
	spawn_scene = holy_nova_scene
	prepare_time = 0.4
	duration = 0.6
	cooldown = 8.0
	max_distance = 150
	focus_cost = 5

func description():
	return "A burst of holy energy damaging enemies around the Cleric"
