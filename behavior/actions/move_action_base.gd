extends Action

class_name MoveActionBase

func _init():
	abortable = true
	min_distance = 25
	# See explanation in action.gd
	filter_with_distance = false
	finish_on_unmet_condition = true

func post_initialize():
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	_start_target_position_refresh()

# Runs the appropriate physics process for entity.
func physics_process(_delta: float):
	super(_delta)
	if finished:
		return
	# I don't think this should happen?
	if not target.valid():
		print("This happened, remove comment above or figure out why. If you don't see this comment in a way, remove this check")
		action_finished()
		return
	if navigation_agent.is_navigation_finished():
		action_finished()
		return
	var next = navigation_agent.get_next_path_position()
	var new_velocity: Vector2 = body.position.direction_to(next) * attributes_component.speed
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)

func _on_velocity_computed(velocity: Vector2):
	body.velocity = velocity
	body.move_and_slide()

# Called periodically to get nav agent target_position.
# For overriding in subclasses.
func _nav_dest() -> Vector2:
	return target_position()

func _start_target_position_refresh():
	while target.valid() and not finished:
		navigation_agent.target_position = _nav_dest()
		await Global.get_tree().create_timer(0.5, false).timeout

func action_finished():
	super()
	if is_instance_valid(navigation_agent):
		navigation_agent.velocity_computed.disconnect(_on_velocity_computed)
	body.velocity = Vector2.ZERO
