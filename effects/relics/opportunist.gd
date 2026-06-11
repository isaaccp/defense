extends Effect

# +25% damage against enemies below 40% HP. Finisher relic.

const BONUS: float = 0.25
const THRESHOLD: float = 0.40

func modify_hit_effect(hit_effect: HitEffect, target: Node, logger: Callable = Callable()) -> void:
	if hit_effect.damage <= 0 or not target:
		return
	var vitals := Component.get_or_null(target, VitalsComponent.component) as VitalsComponent
	if not vitals:
		return
	var current := vitals.get_vital_current(VitalsComponent.VitalType.HEALTH)
	var max_hp := vitals.get_vital_max(VitalsComponent.VitalType.HEALTH)
	if max_hp <= 0:
		return
	if current / max_hp >= THRESHOLD:
		return
	hit_effect.damage_multiplier *= (1.0 + BONUS)
	logger.call("Opportunist added +%d%% damage (target below %d%% HP)" % [int(BONUS * 100), int(THRESHOLD * 100)])
