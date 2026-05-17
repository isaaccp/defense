extends Effect

# Rogue starting bonus relic. "Execute" mechanic — +50% damage vs wounded enemies.
# Pairs naturally with Lowest Health First target sort: rogue finishes off the
# weak ones. Threshold uses target's current HP fraction.

const EXECUTE_THRESHOLD_PCT: float = 0.30
const BONUS_MULTIPLIER: float = 1.5

func modify_hit_effect(hit_effect: HitEffect, target: Node, logger: Callable = Callable()) -> void:
	if not target:
		return
	var vitals := Component.get_or_null(target, VitalsComponent.component) as VitalsComponent
	if not vitals:
		return
	var current = vitals.get_vital_current(VitalsComponent.VitalType.HEALTH)
	var max_hp = vitals.get_vital_max(VitalsComponent.VitalType.HEALTH)
	if max_hp <= 0:
		return
	if current / max_hp > EXECUTE_THRESHOLD_PCT:
		return
	hit_effect.damage_multiplier *= BONUS_MULTIPLIER
	logger.call("Killer's Insight: target at %d%% HP, damage x%.1f" % [
		int(100.0 * current / max_hp), BONUS_MULTIPLIER])
