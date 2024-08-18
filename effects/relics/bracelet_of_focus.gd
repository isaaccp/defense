extends Effect

func modified_action_cooldown(action_def: ActionDef, cooldown: float, logger: Callable = Callable()) -> float:
	logger.call("Bracelet of Focus reduced cooldown by 30%% from %0.1f to %0.1f" % [cooldown, cooldown * 0.7])
	return cooldown * 0.7
