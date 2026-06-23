extends Effect

func modify_hit_effect(hit_effect: HitEffect, target: Node, logger: Callable = Callable()) -> void:
	if not target:
		return
	var vitals = Component.get_or_null(target, VitalsComponent.component) as VitalsComponent
	if vitals and vitals.get_vital_current(VitalsComponent.VitalType.HEALTH) / vitals.get_vital_max(VitalsComponent.VitalType.HEALTH) < 0.3:
		hit_effect.damage_multiplier *= 1.5
		if logger.is_valid():
			logger.call("Executioner's Axe (+50% dmg)")
