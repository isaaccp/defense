extends Effect

var high_focus_params: HighFocusParams

func initialize(params: EffectParams) -> void:
	high_focus_params = params as HighFocusParams
	assert(high_focus_params)
	
func modify_attributes(base_attributes: Attributes) -> void:
	assert(high_focus_params)
	base_attributes.focus_regen *= high_focus_params.focus_regen_multiplier
