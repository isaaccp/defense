extends Effect

# Outgoing damage scales linearly with missing HP, up to +50% at 0 HP.
# Build-around: pair with low-HP playstyle or self-damage mechanics.

const MAX_BONUS: float = 0.50

func modify_hit_effect(hit_effect: HitEffect, _target: Node, logger: Callable = Callable()) -> void:
	if hit_effect.damage <= 0:
		return  # don't buff heals (negative damage)
	var vitals := Component.get_or_null(bearer, VitalsComponent.component) as VitalsComponent
	if not vitals:
		return
	var current := vitals.get_vital_current(VitalsComponent.VitalType.HEALTH)
	var max_hp := vitals.get_vital_max(VitalsComponent.VitalType.HEALTH)
	if max_hp <= 0:
		return
	var missing_frac: float = clampf(1.0 - current / max_hp, 0.0, 1.0)
	var bonus := missing_frac * MAX_BONUS
	if bonus <= 0:
		return
	hit_effect.damage_multiplier *= (1.0 + bonus)
	logger.call("Berserker's Mark added +%d%% damage" % int(round(bonus * 100)))
