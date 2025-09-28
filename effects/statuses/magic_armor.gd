extends Effect

var magic_armor_params: MagicArmorParams

func initialize(params: EffectParams) -> void:
	magic_armor_params = params as MagicArmorParams
	assert(magic_armor_params)
	
func modify_attributes(base_attributes: Attributes) -> void:
	assert(magic_armor_params)
	base_attributes.armor += magic_armor_params.armor_bonus
