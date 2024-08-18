extends ProjectileAttackActionBase

var shots = 3

func _init():
	super()
	# TODO: Enable this when archers have a way to get away from enemies.
	# min_distance = 100
	max_distance = 300
	projectile_scene = preload("res://behavior/actions/scenes/arrow.tscn")
	cooldown = 3.0

func post_initialize():
	for i in range(shots):
		spawn_projectile()
		await Global.get_tree().create_timer(0.33, false).timeout
		# Stop firing arrows if we are aborted.
		if finished:
			return
	await Global.get_tree().create_timer(0.33, false).timeout
	action_finished()

func description():
	return "Fires 3 arrows in 1 second, each of them causing 3 piercing damage to a single target"
