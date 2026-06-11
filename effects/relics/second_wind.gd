extends Effect

# First time the bearer drops below 30% HP this level, instantly heal to
# 50% HP. One-shot survival pivot. Resets every level since the Effect is
# re-instantiated when the character respawns at the next stage.

const TRIGGER_HP_FRAC: float = 0.30
const HEAL_TO_HP_FRAC: float = 0.50

var _fired := false

func on_damage_taken(_damage_taken: int, _attacker_name: String) -> void:
	if _fired:
		return
	var vitals := Component.get_or_null(bearer, VitalsComponent.component) as VitalsComponent
	if not vitals:
		return
	var current := vitals.get_vital_current(VitalsComponent.VitalType.HEALTH)
	var max_hp := vitals.get_vital_max(VitalsComponent.VitalType.HEALTH)
	if max_hp <= 0:
		return
	if current / max_hp < TRIGGER_HP_FRAC:
		_fired = true
		var target_hp := max_hp * HEAL_TO_HP_FRAC
		var delta := target_hp - current
		if delta > 0:
			vitals.apply_vital_change(VitalsComponent.VitalType.HEALTH, delta, true)
