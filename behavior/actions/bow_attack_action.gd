extends Action

class_name BowAttackAction

const arrow_scene = preload("res://behavior/actions/scenes/arrow.tscn")

var arrow: ActionScene

func _init():
	# TODO: Enable this when archers have a way to get away from enemies.
	# min_distance = 100
	max_distance = 300

func spawn_arrow():
	var dir = (target.node.position - body.position).normalized()
	arrow = arrow_scene.instantiate() as ActionScene
	_initialize_action_scene(arrow)
	arrow.look_at(arrow.position + dir)
	arrow.position += dir * 35
	action_sprites.add_child(arrow)

func post_initialize():
	spawn_arrow()
	Global.get_tree().create_timer(1.0, false).timeout.connect(action_finished)
