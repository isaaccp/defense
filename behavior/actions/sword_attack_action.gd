extends Action

const sword_attack_scene = preload("res://behavior/actions/scenes/sword_attack.tscn")

var sword_attack: ActionScene

func _init():
	max_distance = 40
	prepare_time = 0.2
	focus_cost = 1

func post_prepare():
	_swing_sword()

# TODO: Refactor into some basic melee attack action so there is not so much duplication needed.
func _swing_sword():
	sword_attack = spawn_melee_attack(sword_attack_scene, 25.0)
	Global.get_tree().create_timer(0.8, false).timeout.connect(action_finished)

func description():
	return "Performs a sword attack, causing 5 slashing damage to a single target."
