extends Effect

func on_effect_added():
	able_to_act.emit(false)

func on_effect_removed():
	able_to_act.emit(true)
