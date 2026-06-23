extends ProjectileAttackActionBase

func _init():
	super()
	duration = 0.4
	projectile_scene = preload("res://behavior/actions/scenes/poison_dart.tscn")
	min_distance = 0
	max_distance = 250
	prepare_time = 0.2
	focus_cost = 2

func description():
	return "Fires a dart applying Poisoned, dealing damage over 5s"
