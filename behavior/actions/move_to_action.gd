extends Action

func _init():
	abortable = true
	
# Runs the appropriate physics process for entity.
func physics_process(delta: float):
	if not target.node:
		action_finished()
		return
	_start_target_position_refresh(target)
	var next = navigation_agent.get_next_path_position()
	body.velocity = body.position.direction_to(next) * attributes_component.speed
	body.move_and_slide()
	
func _start_target_position_refresh(target: Target):
	while target.node and not finished:
		navigation_agent.target_position = target.node.position
		await Global.get_tree().create_timer(0.25, false).timeout

func action_finished():
	body.velocity = Vector2.ZERO
	super()
