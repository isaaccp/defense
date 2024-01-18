extends ProjectileAttackActionBase

func _init():
	super()
	projectile_scene = preload("res://behavior/actions/scenes/seeking_bolt.tscn")
	min_distance = 100
	max_distance = 300

func post_initialize():
	spawn_projectile()
	Global.get_tree().create_timer(1.5, false).timeout.connect(action_finished)

func description():
	return "Fires a seeking bolt at a target.\nThe bolt will only hit its intended target."
