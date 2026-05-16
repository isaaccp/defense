extends Effect

# Priest class relic. Gain focus equal to 50% of HP healed (rounded).
# Identity: "faith from service — healing returns focus to keep healing."

const FOCUS_FRACTION_OF_HEAL: float = 0.5

func on_heal_applied(amount_healed: int, _target_name: String) -> void:
	var vitals := Component.get_or_null(bearer, VitalsComponent.component) as VitalsComponent
	if not vitals:
		return
	vitals.apply_vital_change(VitalsComponent.VitalType.FOCUS, amount_healed * FOCUS_FRACTION_OF_HEAL, false)
