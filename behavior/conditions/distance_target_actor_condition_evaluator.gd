extends FloatTargetActorConditionEvaluator

func get_value(target: Node2D) -> float:
	return actor.global_position.distance_to(target.global_position)
