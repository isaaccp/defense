extends Action

func _init():
	abortable = true
	
# Runs the appropriate physics process for entity.
func physics_process(target: Node2D, delta: float):
	if not is_instance_valid(target):
		action_finished()
		return
	_start_target_position_refresh(target)
	var next = entity.navigation_agent.get_next_path_position()
	entity.velocity = entity.position.direction_to(next) * entity.speed
	entity.move_and_slide()
	
func _start_target_position_refresh(target: Node2D):
	while is_instance_valid(target) and not finished:
		entity.navigation_agent.target_position = target.position
		await Global.get_tree().create_timer(0.25, false).timeout

func action_finished():
	entity.velocity = Vector2.ZERO
	super()
