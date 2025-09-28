extends Effect

var strength_surge_params: StrengthSurgeParams

func initialize(params: EffectParams) -> void:
	strength_surge_params = params as StrengthSurgeParams
	assert(strength_surge_params)
	
func modify_attributes(attributes: Attributes) -> void:
	assert(strength_surge_params)
	attributes.damage_multiplier *= strength_surge_params.damage_multiplier
