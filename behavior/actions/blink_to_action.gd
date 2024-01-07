extends TeleportActionBase

# Don't jump *exactly* on top of target.
const offset = 20
const teleport_distance = 100

func _init():
	cooldown = 3.0
	min_distance = 120

func update_position():
	# Intentionally using the target position when we started to cast.
	# It's possible the target moved but that's WAI.
	var dir = body.global_position.direction_to(initial_target_pos)
	# This distance check isn't quite needed given min_distance and teleport_distance
	# as set here, but just in case someone copy/pastes this with a different
	# distance.
	var distance = body.global_position.distance_to(initial_target_pos)
	body.global_position += dir * min(teleport_distance, distance - offset)
