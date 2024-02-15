extends Action

const sword_attack_scene = preload("res://behavior/actions/scenes/sword_attack.tscn")

var sword_attack: ActionScene

func _init():
	max_distance = 40
	prepare_time = 0.2

func post_prepare():
	_swing_sword()

func _swing_sword():
	var dir = (target_position(Target.PositionType.HURTBOX) - body.position).normalized()
	sword_attack = sword_attack_scene.instantiate() as ActionScene
	_initialize_action_scene(sword_attack)
	sword_attack.look_at(sword_attack.position + dir)
	sword_attack.position += dir * 15
	action_sprites.add_child(sword_attack)
	Global.get_tree().create_timer(0.8, false).timeout.connect(action_finished)

func description():
	return "Performs a sword attack (TODO: damage)"
