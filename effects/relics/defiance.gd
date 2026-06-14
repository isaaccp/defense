extends Effect

# Knight class relic: Defiance
# Generates Focus based on raw, unmitigated incoming damage.

func modify_incoming_hit_effect(hit_effect: HitEffect, logger: Callable = Callable()) -> void:
	var vitals := Component.get_or_null(bearer, VitalsComponent.component) as VitalsComponent
	if not vitals:
		return
	var raw_damage = hit_effect.adjusted_damage()
	if raw_damage > 0:
		vitals.apply_vital_change(VitalsComponent.VitalType.FOCUS, raw_damage, false)
		logger.call("Defiance generated %0.1f Focus from raw incoming damage" % raw_damage)
