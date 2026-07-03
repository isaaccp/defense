extends Effect

var hasted_params: HastedParams

func initialize(params: EffectParams) -> void:
	hasted_params = params as HastedParams
	assert(hasted_params)

func modify_attributes(attributes: Attributes) -> void:
	attributes.speed *= hasted_params.speed_multiplier

func modified_action_cooldown(action: ActionDef, cooldown: float, logger: Callable = Callable()) -> float:
	var final_cooldown = cooldown / hasted_params.action_speed_multiplier
	logger.call("Haste status reduced cooldown of %s from %0.1fs to %0.1fs" % [action.skill_name, cooldown, final_cooldown])
	return final_cooldown
