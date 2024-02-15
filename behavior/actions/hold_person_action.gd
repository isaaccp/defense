extends SpawnAtTargetNodePositionAction

const hold_person_scene = preload("res://behavior/actions/scenes/hold_person.tscn")

# TODO: Look into turning stuff like this into a resource.

func _init():
	spawn_scene = hold_person_scene
	prepare_time = 0.5
	duration = 0.5
	cooldown = 5.0
	max_distance = 200

func description():
	return "Paralyzes a target enemy"
