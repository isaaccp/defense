extends SpawnAtTargetNodePositionAction

const battle_cry_scene = preload("res://behavior/actions/scenes/battle_cry.tscn")

func _init():
	spawn_scene = battle_cry_scene
	prepare_time = 0.5
	duration = 0.8
	cooldown = 12.0
	max_distance = 50
	focus_cost = 0

func description():
	return "Bellows a war cry, granting Haste to all nearby allies for 5s"
