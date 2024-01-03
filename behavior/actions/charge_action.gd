extends MoveToAction

class_name ChargeAction

# If we moved more than this, trigger strengthened at the end.
const charge_threshold = 100.0
var original_position: Vector2

func _init():
	cooldown = 4.0

func post_initialize():
	original_position = body.global_position
	status_component.set_status(def.id, StatusDef.Id.SWIFTNESS, -1)

func action_finished():
	super()
	status_component.remove_status(def.id, StatusDef.Id.SWIFTNESS)
	if original_position.distance_squared_to(body.global_position) > charge_threshold * charge_threshold:
		status_component.set_status(def.id, StatusDef.Id.STRENGTH_SURGE, 2.0)
