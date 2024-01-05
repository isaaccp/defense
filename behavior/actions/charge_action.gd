extends MoveToAction

class_name ChargeAction

# If we moved more than this, trigger strengthened at the end.
const charge_threshold = 100.0
var original_position: Vector2

func _init():
	cooldown = 4.0
	min_distance = 50

func post_initialize():
	original_position = body.global_position
	status_component.set_status(def.id, StatusDef.Id.SWIFTNESS, -1)

func action_finished():
	super()
	status_component.remove_status(def.id, StatusDef.Id.SWIFTNESS)
	var distance = original_position.distance_to(body.global_position)
	if distance >= charge_threshold:
		action_log("%0.1f (>= %0.1f), triggering surge" % [distance, charge_threshold])
		status_component.set_status(def.id, StatusDef.Id.STRENGTH_SURGE, 2.0)
	else:
		action_log("%0.1f (< %0.1f), not triggering surge" % [distance, charge_threshold])
