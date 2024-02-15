extends ProjectileAttackActionBase

func _init():
	super()
	projectile_scene = preload("res://behavior/actions/scenes/seeking_bolt.tscn")
	min_distance = 100
	max_distance = 300
	prepare_time = 0.5

func post_prepare():
	spawn_projectile()
	Global.get_tree().create_timer(1.0, false).timeout.connect(action_finished)

func description():
	return "Fires a seeking bolt at a target.\nThe bolt will only hit its intended target."
