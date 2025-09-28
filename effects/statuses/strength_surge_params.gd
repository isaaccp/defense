extends EffectParams

class_name StrengthSurgeParams

@export var damage_multiplier: float

static func make(damage_multiplier: float) -> StrengthSurgeParams:
	var params = StrengthSurgeParams.new()
	params.damage_multiplier = damage_multiplier
	return params
