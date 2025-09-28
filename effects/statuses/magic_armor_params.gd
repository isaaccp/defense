extends EffectParams

class_name MagicArmorParams

@export var armor_bonus: int

static func make(armor_bonus: float) -> MagicArmorParams:
	var params = MagicArmorParams.new()
	params.armor_bonus = armor_bonus
	return params
