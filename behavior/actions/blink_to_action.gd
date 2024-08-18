extends TeleportActionBase

# Don't jump *exactly* on top of target.
const offset = 20
const teleport_distance = 200

func _init():
	cooldown = 3.0
	min_distance = 20

func update_position():
	# Using the target position when we started to cast.
	# TODO: Change to use the new target position.
	var dir = body.global_position.direction_to(initial_target_pos)
	var distance = body.global_position.distance_to(initial_target_pos)
	body.global_position += dir * min(teleport_distance, distance - offset)

func description() -> String:
	return "Teleports towards a target for a max distance of 200"
