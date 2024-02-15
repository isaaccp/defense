extends Action

const fire_burst_scene = preload("res://behavior/actions/scenes/fire_burst.tscn")

var fire_burst: ActionScene

func _init():
	max_distance = 80
	cooldown = 5.0
	prepare_time = 0.5

func post_prepare():
	_fire_burst()

func _fire_burst():
	var dir = (target_position(Target.PositionType.HURTBOX) - body.position).normalized()
	fire_burst = fire_burst_scene.instantiate() as ActionScene
	_initialize_action_scene(fire_burst)
	fire_burst.look_at(fire_burst.position + dir)
	fire_burst.position += dir * 15
	action_sprites.add_child(fire_burst)
	Global.get_tree().create_timer(0.5, false).timeout.connect(action_finished)

func description():
	return "Creates a burst of fire in front of the caster."
