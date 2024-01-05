extends IntTargetNodeConditionEvaluator

func get_value(node: Node2D) -> int:
	return body.global_position.distance_to(node.global_position)
