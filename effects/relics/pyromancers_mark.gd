extends Effect

# +30% damage on fire damage hits. Universal anchor for the fire-damage
# chain: Wizard's Fire Burst benefits directly; classes with Ember Brand
# or Igniter Quiver also get the bonus when their attacks convert.

const fire_damage_type = preload("res://game_logic/damage_types/fire.tres")
const BONUS: float = 0.30

func modify_hit_effect(hit_effect: HitEffect, _target: Node, logger: Callable = Callable()) -> void:
	if hit_effect.damage <= 0:
		return
	if hit_effect.damage_type != fire_damage_type:
		return
	hit_effect.damage_multiplier *= (1.0 + BONUS)
	logger.call("Pyromancer's Mark added +%d%% fire damage" % int(BONUS * 100))
