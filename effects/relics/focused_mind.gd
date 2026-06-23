extends Effect

func modify_incoming_hit_effect(hit_effect: HitEffect, logger: Callable = Callable()) -> void:
	var vitals = Component.get_or_null(bearer, VitalsComponent.component) as VitalsComponent
	if vitals and vitals.get_vital_current(VitalsComponent.VitalType.FOCUS) > (vitals.get_vital_max(VitalsComponent.VitalType.FOCUS) * 0.75):
		hit_effect.damage_multiplier *= 0.75
		if logger.is_valid():
			logger.call("Focused Mind (-25% incoming damage)")
