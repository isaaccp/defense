extends ProjectileAttackActionBase

func _init():
	super()
	projectile_scene = preload("res://behavior/actions/scenes/arcane_blast.tscn")
	min_distance = 100
	max_distance = 300
	prepare_time = 0.4
	focus_cost = 3
	cooldown = 4.0

func post_prepare():
	spawn_projectile()
	Global.get_tree().create_timer(1.0, false).timeout.connect(action_finished)

func description():
	return "Fires an arcane blast in a straight line at a target, causing 10 arcane damage."
