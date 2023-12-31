extends Action

var first = true
# If we moved more than this, trigger strengthened at the end.
var charge_threshold_squared = 100.0 * 100.0
var original_position: Vector2

func _init():
	abortable = true
	
# Runs the appropriate physics process for entity.
func physics_process(target: Node2D, delta: float):
	if first:
		first = false
		original_position = body.global_position
		status_component.set_status(def.id, StatusDef.Id.SWIFTNESS, -1)
	if not is_instance_valid(target):
		action_finished()
		return
	_start_target_position_refresh(target)
	var next = navigation_agent.get_next_path_position()
	body.velocity = body.position.direction_to(next) * attributes_component.speed
	body.move_and_slide()
	
func _start_target_position_refresh(target: Node2D):
	while is_instance_valid(target) and not finished:
		navigation_agent.target_position = target.position
		await Global.get_tree().create_timer(0.25, false).timeout

func action_finished():
	body.velocity = Vector2.ZERO
	status_component.remove_status(def.id, StatusDef.Id.SWIFTNESS)
	if original_position.distance_squared_to(body.global_position) > charge_threshold_squared:
		status_component.set_status(def.id, StatusDef.Id.STRENGTH_SURGE, 2.0)
	super()
