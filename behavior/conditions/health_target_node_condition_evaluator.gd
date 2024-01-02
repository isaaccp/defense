extends IntTargetNodeConditionEvaluator

class_name HealthTargetNodeConditionEvaluator

func get_value(node: Node2D) -> int:
	var health = Component.get_health_component_or_null(node)
	if not health:
		get_value_failed = true
		return 0
	return health.health
