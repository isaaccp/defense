extends Action

class_name SwordAttackAction

const sword_attack_scene = preload("res://behavior/actions/scenes/sword_attack.tscn")

var sword_attack: ActionScene

func _init():
	max_distance = 40

func post_initialize():
	_swing_sword.call_deferred()

func _swing_sword():
	# Wait a bit for the hit.
	await Global.get_tree().create_timer(0.2, false).timeout
	if not _after_await_check():
		return
	var dir = (target.node.position - body.position).normalized()
	sword_attack = sword_attack_scene.instantiate() as ActionScene
	_initialize_action_scene(sword_attack)
	sword_attack.look_at(sword_attack.position + dir)
	sword_attack.position += dir * 35
	action_sprites.add_child(sword_attack)
	Global.get_tree().create_timer(0.8, false).timeout.connect(action_finished)
