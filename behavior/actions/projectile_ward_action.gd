extends SpawnAtTargetNodePositionAction

const projectile_ward_scene = preload("res://behavior/actions/scenes/projectile_ward.tscn")

# TODO: Look into turning stuff like this into a resource.

func _init():
	spawn_scene = projectile_ward_scene
	prepare_time = 0.25
	duration = 0.5
	cooldown = 5.0
	max_distance = 200

func description():
	return "Protects against ranged damage"
