extends FloatTargetNodeConditionEvaluator

func get_value(node: Node2D) -> float:
	return body.global_position.distance_to(node.global_position)
