extends MoveActionBase

# How far to run in a single activation.
# Needs to be at least one grid cell to actually move.
@export var move_away_distance = 100.0

func _init():
	# Unlike the base MoveTo, we may want to trigger MoveAway arbitrarily close.
	min_distance = 0
	finish_on_unmet_condition = true

func post_initialize():
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	# Single-shot activation. There's no 'arriving' at running away.
	navigation_agent.target_position = _nav_dest(target)


func _nav_dest(target: Target) -> Vector2:
	var dir = target_position().direction_to(body.global_position)
	return body.position + dir * move_away_distance
