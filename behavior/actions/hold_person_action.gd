extends SpawnAtTargetNodePositionAction

const hold_person_scene = preload("res://behavior/actions/scenes/hold_person.tscn")

# TODO: Look into turning stuff like this into a resource.

func _init():
	spawn_scene = hold_person_scene
	duration = 1.0
	cooldown = 5.0
	max_distance = 200
