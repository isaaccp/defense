extends SpawnAtTargetNodePositionAction

const whirlwind_scene = preload("res://behavior/actions/scenes/whirlwind.tscn")

func _init():
	spawn_scene = whirlwind_scene
	prepare_time = 0.3
	duration = 0.6
	cooldown = 6.0
	max_distance = 50
	focus_cost = 4

func description():
	return "Spin and hit all adjacent enemies for physical damage"
