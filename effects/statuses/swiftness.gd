extends Effect

var swiftness_params: SwiftnessParams

func initialize(params: EffectParams) -> void:
	swiftness_params = params as SwiftnessParams
	assert(swiftness_params)
	
func modify_attributes(attributes: Attributes) -> void:
	assert(swiftness_params)
	attributes.speed *= swiftness_params.speed_multiplier
