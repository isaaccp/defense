extends Action

func _init():
	abortable = true
	
# Runs the appropriate physics process for entity.
func physics_process(target: Node2D, delta: float):
	if not is_instance_valid(target):
		action_finished()
		return
	_start_target_position_refresh(target)
	var next = navigation_agent.get_next_path_position()
	body.velocity = body.position.direction_to(next) * body.speed
	body.move_and_slide()
	
func _start_target_position_refresh(target: Node2D):
	while is_instance_valid(target) and not finished:
		navigation_agent.target_position = target.position
		await Global.get_tree().create_timer(0.25, false).timeout

func action_finished():
	body.velocity = Vector2.ZERO
	super()
