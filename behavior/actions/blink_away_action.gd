extends BlinkAction

class_name BlinkAwayAction

func _init():
	cooldown = 3.0
	blink_distance = 100

func update_position():
	var dir = initial_target_pos.direction_to(body.global_position)
	body.global_position += dir * blink_distance
