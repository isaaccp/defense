extends ProjectileAttackActionBase

func _init():
	super()
	projectile_scene = preload("res://behavior/actions/scenes/arrow.tscn")
	# TODO: Enable this when archers have a way to get away from enemies.
	# min_distance = 100
	max_distance = 300
	prepare_time = 0.3

func post_prepare():
	spawn_projectile()
	Global.get_tree().create_timer(0.7, false).timeout.connect(action_finished)

func description():
	return "Fires an arrow at a single target, causing 3 piercing damage"
