extends SpawnAtTargetNodePositionAction

const magic_armor_scene = preload("res://behavior/actions/scenes/magic_armor.tscn")

func _init():
	spawn_scene = magic_armor_scene
	prepare_time = 0.25
	duration = 0.5
	cooldown = 5.0
	max_distance = 200

func description():
	return "Grants 1 point of armor to the target"
