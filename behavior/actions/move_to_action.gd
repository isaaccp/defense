extends Action

class_name MoveToAction

func _init():
	abortable = true
	min_distance = 25
	# See explanation in action.gd
	filter_with_distance = false

# Runs the appropriate physics process for entity.
func physics_process(delta: float):
	# I don't think this should happen?
	if not target.node:
		action_finished()
		return
	_start_target_position_refresh(target)
	if navigation_agent.is_navigation_finished():
		action_finished()
		return
	var next = navigation_agent.get_next_path_position()
	body.velocity = body.position.direction_to(next) * attributes_component.speed
	body.move_and_slide()

func _start_target_position_refresh(target: Target):
	while target.node and not finished:
		navigation_agent.target_position = target.node.position
		await Global.get_tree().create_timer(0.25, false).timeout

func action_finished():
	super()
	body.velocity = Vector2.ZERO
