extends IntTargetActorConditionEvaluator

func get_value(target: Actor) -> int:
	var vitals: VitalsComponent = target.get_component_or_null(VitalsComponent)
	if not vitals:
		get_value_failed = true
		return 0
	return int(vitals.get_vital_current(VitalsComponent.VitalType.HEALTH))
