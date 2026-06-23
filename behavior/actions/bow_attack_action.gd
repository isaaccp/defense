extends ProjectileAttackActionBase

func _init():
	super()
	duration = 0.7
	projectile_scene = preload("res://behavior/actions/scenes/arrow.tscn")
	min_distance = 100
	max_distance = 300
	prepare_time = 0.3
	focus_cost = 1

func description():
	return "Fires an arrow at a single target, causing 3 piercing damage"
