extends Effect

func on_heal_applied(amount_healed: int, _target_name: String) -> void:
	if amount_healed > 0:
		var vitals = Component.get_or_null(bearer, VitalsComponent.component) as VitalsComponent
		if vitals:
			vitals.apply_vital_change(VitalsComponent.VitalType.HEALTH, round(amount_healed * 0.5), true)
