extends EffectParams

class_name HighFocusParams

@export var focus_regen_multiplier: float

static func make(focus_regen_multiplier: float) -> HighFocusParams:
	var params = HighFocusParams.new()
	params.focus_regen_multiplier = focus_regen_multiplier
	return params
