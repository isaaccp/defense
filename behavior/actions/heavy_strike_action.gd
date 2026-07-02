extends Action

const heavy_strike_scene = preload("res://behavior/actions/scenes/heavy_strike.tscn")

var heavy_strike: ActionScene

func _init():
	max_distance = 40
	prepare_time = 0.2
	focus_cost = 4
	cooldown = 8.0

func post_prepare():
	_heavy_strike()

# TODO: Refactor into some basic melee attack action so there is not so much duplication needed.
func _heavy_strike():
	heavy_strike = spawn_melee_attack(heavy_strike_scene, 25.0)
	Global.get_tree().create_timer(0.8, false).timeout.connect(action_finished)

func description():
	return "Performs a heavy strike, causing 15 physical damage to a single target."
