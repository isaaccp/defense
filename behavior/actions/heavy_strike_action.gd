extends Action

const heavy_strike_scene = preload("res://behavior/actions/scenes/heavy_strike.tscn")

var heavy_strike: ActionScene
var attack_dir: Vector2

func _init():
	max_distance = 40
	prepare_time = 0.2
	focus_cost = 4
	cooldown = 8.0

func post_initialize():
	attack_dir = attack_direction()

func post_prepare():
	_heavy_strike()

# TODO: Refactor into some basic melee attack action so there is not so much duplication needed.
func _heavy_strike():
	heavy_strike = heavy_strike_scene.instantiate() as ActionScene
	_initialize_action_scene(heavy_strike)
	heavy_strike.look_at(heavy_strike.position + attack_dir)
	action_sprites.add_child(heavy_strike)
	heavy_strike.global_position = actor.attack_position() + attack_dir * 25
	Global.get_tree().create_timer(0.8, false).timeout.connect(action_finished)

func description():
	return "Performs a heavy strike, causing 15 physical damage to a single target."
