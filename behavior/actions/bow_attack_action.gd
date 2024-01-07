extends ProjectileAttackActionBase

func _init():
	super()
	projectile_scene = preload("res://behavior/actions/scenes/arrow.tscn")
	# TODO: Enable this when archers have a way to get away from enemies.
	# min_distance = 100
	max_distance = 300

func post_initialize():
	spawn_projectile()
	Global.get_tree().create_timer(1.0, false).timeout.connect(action_finished)

func description():
	return "Fires an arrow at a target"
