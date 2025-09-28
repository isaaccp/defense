extends EffectParams

class_name SwiftnessParams

@export var speed_multiplier: float

static func make(speed_multiplier: float) -> SwiftnessParams:
	var params = SwiftnessParams.new()
	params.speed_multiplier = speed_multiplier
	return params
