extends Action

# If we moved more than this, trigger strengthened at the end.
var charge_threshold_squared = 100.0 * 100.0
var original_position: Vector2

func _init():
	abortable = true

func post_initialize():
	original_position = body.global_position
	status_component.set_status(def.id, StatusDef.Id.SWIFTNESS, -1)
	
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
	status_component.remove_status(def.id, StatusDef.Id.SWIFTNESS)
	if original_position.distance_squared_to(body.global_position) > charge_threshold_squared:
		status_component.set_status(def.id, StatusDef.Id.STRENGTH_SURGE, 2.0)
	super()
