extends Action

const cleave_scene = preload("res://behavior/actions/scenes/cleave.tscn")

var cleave: ActionScene

func _init():
	max_distance = 40
	cooldown = 4.0

func post_initialize():
	_swing_sword.call_deferred()

func _swing_sword():
	# Wait a bit for the hit.
	await Global.get_tree().create_timer(0.2, false).timeout
	if not _after_await_check(true):
		return
	var dir = (target_position(Target.PositionType.HURTBOX) - body.position).normalized()
	cleave = cleave_scene.instantiate() as ActionScene
	_initialize_action_scene(cleave)
	cleave.look_at(cleave.position + dir)
	cleave.position += dir * 15
	cleave.hit.connect(_on_hit)
	action_sprites.add_child(cleave)
	Global.get_tree().create_timer(0.8, false).timeout.connect(action_finished)

func description():
	return "Performs a sword attack. If enemy is killed, cooldown is waived. (TODO: damage)"

func _on_hit(hit_result: HitResult):
	if hit_result.destroyed:
		action_log("Cleave: Cooldown removed as enemy was destroyed")
		cooldown = 0.0
