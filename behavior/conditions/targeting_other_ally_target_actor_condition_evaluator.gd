extends TargetingAllyTargetActorConditionEvaluator

func _is_valid_target(their_target: Actor) -> bool:
	return their_target != actor
