extends Effect

const cooldown_reduction_percentage: int = 30
const cooldown_multiplier = 1 - float(100-cooldown_reduction_percentage) / 100.0

func modified_action_cooldown(action: ActionDef, cooldown: float, logger: Callable = Callable()) -> float:
	logger.call("Bracelet of Focus reduced cooldown by %d%% from %0.1f to %0.1f" % [cooldown_reduction_percentage, cooldown, cooldown * cooldown_multiplier])
	return cooldown * cooldown_multiplier
