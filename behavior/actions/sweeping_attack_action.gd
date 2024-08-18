extends Action

const sweeping_attack_scene = preload("res://behavior/actions/scenes/sweeping_attack.tscn")

var sweeping_attack: ActionScene
var attack_dir: Vector2

func _init():
	max_distance = 40
	prepare_time = 0.2
	cooldown = 4.0

func post_initialize():
	attack_dir = attack_direction()

func post_prepare():
	_sweeping_attack()

func _sweeping_attack():
	sweeping_attack = sweeping_attack_scene.instantiate() as ActionScene
	_initialize_action_scene(sweeping_attack)
	sweeping_attack.look_at(sweeping_attack.position + attack_dir)
	action_sprites.add_child(sweeping_attack)
	sweeping_attack.global_position = actor.attack_position() + attack_dir * 25
	Global.get_tree().create_timer(0.8, false).timeout.connect(action_finished)

func description():
	return "Performs a sweeping sword attack that hits all enemies reached (TODO: damage)"
