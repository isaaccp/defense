extends TeleportActionBase

const teleport_distance = 500

func _init():
	cooldown = 5.0

func update_position():
	var dir = initial_target_pos.direction_to(body.global_position)
	body.global_position += dir * teleport_distance
