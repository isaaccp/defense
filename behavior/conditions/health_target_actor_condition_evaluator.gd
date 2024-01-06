extends IntTargetActorConditionEvaluator

func get_value(target: Actor) -> int:
	var health = Component.get_health_component_or_null(target)
	if not health:
		get_value_failed = true
		return 0
	return health.health
