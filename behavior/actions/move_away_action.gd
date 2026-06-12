extends MoveActionBase

# How far to run in a single activation.
# Needs to be at least one grid cell to actually move.
@export var move_away_distance = 100.0

func _init():
	# Unlike the base MoveTo, we may want to trigger MoveAway arbitrarily close.
	min_distance = 0
	finish_on_unmet_condition = true

func post_make():
	if def.params.placeholder_set(SkillParams.PlaceholderId.FLOAT_VALUE):
		max_distance = def.params.float_value.value

func post_initialize():
	super.post_initialize()

func _nav_dest() -> Vector2:
	var dir = target_position().direction_to(body.global_position)
	return body.position + dir * move_away_distance

func description() -> String:
	return "Moves away from the target"
