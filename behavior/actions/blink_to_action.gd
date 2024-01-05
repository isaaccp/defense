extends BlinkAction

class_name BlinkToAction

# Don't jump *exactly* on top of target.
const offset = 20

func _init():
	cooldown = 3.0
	min_distance = 120
	blink_distance = 100

func update_position():
	# Intentionally using the target position when we started to cast.
	# It's possible the target moved but that's WAI.
	var dir = body.global_position.direction_to(initial_target_pos)
	# This distance check isn't quite needed given min_distance and blink_distance
	# as set here, but that way we can subclass this with bigger blink_distance
	# and have this taken care of.
	var distance = body.global_position.distance_to(initial_target_pos)
	body.global_position += dir * min(blink_distance, distance - offset)
