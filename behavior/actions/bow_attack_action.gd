extends Action

const arrow_scene = preload("res://behavior/actions/scenes/arrow.tscn")

var arrow: ActionScene
var first = true

func _init():
	distance = 300

func physics_process(target: Node2D, delta: float):
	if first:
		first = false
		var dir = (target.position - body.position).normalized()
		arrow = arrow_scene.instantiate() as ActionScene
		_initialize_action_scene(arrow)
		arrow.look_at(arrow.position + dir)
		arrow.position += dir * 35
		action_sprites.add_child(arrow)
		Global.get_tree().create_timer(1.0, false).timeout.connect(action_finished)
