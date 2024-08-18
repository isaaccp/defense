extends TeleportActionBase

const teleport_distance = 200

func _init():
	cooldown = 3.0

func update_position():
	var dir = initial_target_pos.direction_to(body.global_position)
	body.global_position += dir * teleport_distance

func description() -> String:
	return "Teleports away from target for a distance of 200"
