extends Action

const mace_attack_scene = preload("res://behavior/actions/scenes/sword_attack.tscn")

var mace_attack: ActionScene
var attack_dir: Vector2

func _init():
	max_distance = 40
	prepare_time = 0.2
	focus_cost = 1

func post_initialize():
	attack_dir = attack_direction()

func post_prepare():
	_swing_mace()

# TODO: Refactor into some basic melee attack action so there is not so much duplication needed.
func _swing_mace():
	mace_attack = mace_attack_scene.instantiate() as ActionScene
	_initialize_action_scene(mace_attack)
	mace_attack.look_at(mace_attack.position + attack_dir)
	action_sprites.add_child(mace_attack)
	mace_attack.global_position = actor.attack_position() + attack_dir * 25
	Global.get_tree().create_timer(0.8, false).timeout.connect(action_finished)

func description():
	return "Performs a mace attack, causing 5 slashing damage to a single target."
