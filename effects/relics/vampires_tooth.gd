extends Effect

func on_enemy_killed(_victim_name: String) -> void:
	var vitals = Component.get_or_null(bearer, VitalsComponent.component) as VitalsComponent
	if vitals:
		vitals.apply_vital_change(VitalsComponent.VitalType.HEALTH, 1.0, true)
