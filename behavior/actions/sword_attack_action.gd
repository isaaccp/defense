extends Action

const sword_attack_scene = preload("res://behavior/actions/scenes/sword_attack.tscn")

var sword_attack: ActionScene
var attack_dir: Vector2

func _init():
	max_distance = 50
	prepare_time = 0.2

func post_initialize():
	attack_dir = (target_position(Target.PositionType.HURTBOX) - body.position).normalized()

func post_prepare():
	_swing_sword()

func _swing_sword():
	sword_attack = sword_attack_scene.instantiate() as ActionScene
	_initialize_action_scene(sword_attack)
	sword_attack.look_at(sword_attack.position + attack_dir)
	sword_attack.position += attack_dir * 25
	action_sprites.add_child(sword_attack)
	Global.get_tree().create_timer(0.8, false).timeout.connect(action_finished)

func description():
	return "Performs a sword attack (TODO: damage)"
