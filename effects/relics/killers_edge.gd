extends Effect

# Rogue class relic: Killer's Edge
# Gain 2 Focus per enemy killed, and 0.5 Focus when hitting enemies under 50% HP.

const FOCUS_PER_KILL: float = 2.0
const FOCUS_PER_EXECUTE_HIT: float = 0.5

func on_enemy_killed(_victim_name: String) -> void:
	var vitals := Component.get_or_null(bearer, VitalsComponent.component) as VitalsComponent
	if not vitals:
		return
	vitals.apply_vital_change(VitalsComponent.VitalType.FOCUS, FOCUS_PER_KILL, false)

func modify_hit_effect(hit_effect: HitEffect, target: Node, logger: Callable = Callable()) -> void:
	if not target:
		return
	var target_vitals := Component.get_or_null(target, VitalsComponent.component) as VitalsComponent
	if not target_vitals:
		return
	
	# Check if target is under 50% HP
	var current_hp = target_vitals.get_vital_current(VitalsComponent.VitalType.HEALTH)
	var max_hp = target_vitals.get_vital_max(VitalsComponent.VitalType.HEALTH)
	if max_hp > 0 and (current_hp / max_hp) < 0.5:
		var vitals := Component.get_or_null(bearer, VitalsComponent.component) as VitalsComponent
		if vitals:
			vitals.apply_vital_change(VitalsComponent.VitalType.FOCUS, FOCUS_PER_EXECUTE_HIT, false)
			logger.call("Killer's Edge generated %0.1f Focus from hitting wounded target" % FOCUS_PER_EXECUTE_HIT)
