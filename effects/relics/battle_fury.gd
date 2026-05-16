extends Effect

# Warrior class relic. Each HP of damage taken converts to 1 focus.
# Identity: "rage builds with adversity."

const FOCUS_PER_HP_TAKEN: float = 1.0

func on_damage_taken(damage_taken: int, _attacker_name: String) -> void:
	var vitals := Component.get_or_null(bearer, VitalsComponent.component) as VitalsComponent
	if not vitals:
		return
	vitals.apply_vital_change(VitalsComponent.VitalType.FOCUS, damage_taken * FOCUS_PER_HP_TAKEN, false)
