extends Effect

# Priest class relic: Unyielding Hope
# Gain Focus regeneration based on the missing HP percentage of the party.

const BASE_REGEN_PER_SECOND: float = 2.0

func on_process(delta: float) -> void:
	var heroes = Global.get_tree().get_nodes_in_group("heroes")
	if heroes.is_empty():
		return
	
	var total_max_hp: float = 0.0
	var total_current_hp: float = 0.0
	
	for hero in heroes:
		var vitals := Component.get_or_null(hero, VitalsComponent.component) as VitalsComponent
		if vitals:
			total_max_hp += vitals.get_vital_max(VitalsComponent.VitalType.HEALTH)
			total_current_hp += vitals.get_vital_current(VitalsComponent.VitalType.HEALTH)
			
	if total_max_hp > 0:
		var missing_percentage = 1.0 - (total_current_hp / total_max_hp)
		if missing_percentage > 0:
			var focus_gained = BASE_REGEN_PER_SECOND * missing_percentage * delta
			var vitals := Component.get_or_null(bearer, VitalsComponent.component) as VitalsComponent
			if vitals:
				vitals.apply_vital_change(VitalsComponent.VitalType.FOCUS, focus_gained, false)
