extends SpawnAtTargetNodePositionAction

const lightning_scene = preload("res://behavior/actions/scenes/lightning_strike.tscn")

func _init():
	spawn_scene = lightning_scene
	prepare_time = 0.5
	duration = 0.8
	cooldown = 12.0
	max_distance = 9999
	focus_cost = 6

func description():
	return "Calls down lightning on an enemy anywhere, dealing high damage"
