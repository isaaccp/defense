extends SpawnAtTargetNodePositionAction

const frost_nova_scene = preload("res://behavior/actions/scenes/frost_nova.tscn")

func _init():
	spawn_scene = frost_nova_scene
	prepare_time = 0.3
	duration = 0.5
	cooldown = 8.0
	max_distance = 150
	focus_cost = 4

func description():
	return "A blast of ice that damages and slows nearby enemies"
