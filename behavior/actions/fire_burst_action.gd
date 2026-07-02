extends Action

const fire_burst_scene = preload("res://behavior/actions/scenes/fire_burst.tscn")

var fire_burst: ActionScene

func _init():
	max_distance = 80
	cooldown = 5.0
	prepare_time = 0.5
	focus_cost = 4

func post_prepare():
	_fire_burst()

func _fire_burst():
	fire_burst = spawn_melee_attack(fire_burst_scene, 15.0)
	Global.get_tree().create_timer(0.5, false).timeout.connect(action_finished)

func description():
	return "Creates a burst of fire in front of the caster that causes 8 fire damage in a small area."
