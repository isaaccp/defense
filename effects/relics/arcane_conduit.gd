extends Effect

# +10% damage on magical (arcane or elemental) damage types. Nerfed
# version: small enough that it complements rather than defines wizard
# builds.

const BONUS: float = 0.1

func modify_hit_effect(hit_effect: HitEffect, _target: Node, logger: Callable = Callable()) -> void:
	if hit_effect.damage <= 0 or not hit_effect.damage_type:
		return
	var mt: int = hit_effect.damage_type.macro_type
	if mt != DamageType.MacroType.ARCANE and mt != DamageType.MacroType.ELEMENTAL:
		return
	hit_effect.damage_multiplier *= (1.0 + BONUS)
	logger.call("Arcane Conduit added +%d%% magical damage" % int(BONUS * 100))
