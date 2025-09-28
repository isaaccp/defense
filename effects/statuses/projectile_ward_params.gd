extends EffectParams

class_name ProjectileWardParams

@export var ranged_attack_resistance: int

static func make(ranged_attack_resistance: float) -> ProjectileWardParams:
	var params = ProjectileWardParams.new()
	params.ranged_attack_resistance = ranged_attack_resistance
	return params
