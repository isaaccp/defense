extends Action

const sword_attack_scene = preload("res://behavior/actions/scenes/sword_attack.tscn")

var first = true
var sword_attack: ActionScene

func _init():
	distance = 40

func physics_process(target: Node2D, delta: float):
	if first:
		first = false
		var dir = (target.position - body.position).normalized()
		sword_attack = sword_attack_scene.instantiate() as ActionScene
		_initialize_action_scene(sword_attack)
		sword_attack.look_at(sword_attack.position + dir)
		sword_attack.position += dir * 35
		action_sprites.add_child(sword_attack)
		Global.get_tree().create_timer(1.0, false).timeout.connect(action_finished)
