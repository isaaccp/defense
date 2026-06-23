extends SpawnAtTargetNodePositionAction

const shield_wall_scene = preload("res://behavior/actions/scenes/shield_wall.tscn")

func _init():
	spawn_scene = shield_wall_scene
	prepare_time = 0.25
	duration = 0.5
	cooldown = 10.0
	max_distance = 200
	focus_cost = 3

func description():
	return "Grants Fortified, reducing damage taken by 50% for 5s"
