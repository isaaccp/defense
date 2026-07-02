extends Action

const mace_attack_scene = preload("res://behavior/actions/scenes/sword_attack.tscn")

var mace_attack: ActionScene

func _init():
	max_distance = 40
	prepare_time = 0.2
	focus_cost = 1

func post_prepare():
	_swing_mace()

# TODO: Refactor into some basic melee attack action so there is not so much duplication needed.
func _swing_mace():
	mace_attack = spawn_melee_attack(mace_attack_scene, 25.0)
	Global.get_tree().create_timer(0.8, false).timeout.connect(action_finished)

func description():
	return "Performs a mace attack, causing 5 slashing damage to a single target."
