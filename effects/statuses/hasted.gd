extends Effect

var hasted_params: HastedParams

func initialize(params: EffectParams) -> void:
	hasted_params = params as HastedParams
	assert(hasted_params)

func modify_attributes(attributes: Attributes) -> void:
	attributes.speed *= hasted_params.speed_multiplier

func modified_action_cooldown(action: ActionDef, cooldown: float, logger: Callable = Callable()) -> float:
	return cooldown / hasted_params.action_speed_multiplier
