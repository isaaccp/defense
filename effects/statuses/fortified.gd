extends Effect

var fortified_params: FortifiedParams

func initialize(params: EffectParams) -> void:
	fortified_params = params as FortifiedParams
	assert(fortified_params)

func modify_incoming_hit_effect(hit_effect: HitEffect, logger: Callable = Callable()) -> void:
	hit_effect.damage_multiplier *= fortified_params.damage_multiplier
	logger.call("Fortified: Damage reduced by %d%%" % [(1.0 - fortified_params.damage_multiplier) * 100])
