extends FloatPositionConditionEvaluator

func get_value(target: Vector2) -> float:
	return actor.global_position.distance_to(target)
