extends Effect

# +1% damage per OTHER relic this character owns. Snowballs as your run
# stacks relics; cheap on its own but synergizes with every other relic.

const BONUS_PER_RELIC: float = 0.01

func modify_hit_effect(hit_effect: HitEffect, _target: Node, logger: Callable = Callable()) -> void:
	if hit_effect.damage <= 0:
		return
	var actuator := Component.get_or_null(bearer, EffectActuatorComponent.component) as EffectActuatorComponent
	if not actuator:
		return
	# Exclude self from the count.
	var other_count: int = max(0, actuator.relics.size() - 1)
	if other_count == 0:
		return
	var bonus := other_count * BONUS_PER_RELIC
	hit_effect.damage_multiplier *= (1.0 + bonus)
	logger.call("Collector added +%d%% damage (%d other relics)" % [int(bonus * 100), other_count])
