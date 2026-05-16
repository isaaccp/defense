extends Effect

# Rogue class relic. Each enemy kill grants flat focus.
# Identity: "combo high from finishing."

const FOCUS_PER_KILL: float = 2.0

func on_enemy_killed(_victim_name: String) -> void:
	var vitals := Component.get_or_null(bearer, VitalsComponent.component) as VitalsComponent
	if not vitals:
		return
	vitals.apply_vital_change(VitalsComponent.VitalType.FOCUS, FOCUS_PER_KILL, false)
