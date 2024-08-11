extends Effect

const slashing_damage_type = preload("res://game_logic/damage_types/slashing.tres")

func modify_hit_effect(hit_effect: HitEffect, logger: Callable = Callable()) -> void:
	if hit_effect.damage_type.name == slashing_damage_type.name:
		logger.call("Vorpal Blade increased flat armor pen by 1")
		hit_effect.flat_armor_pen += 1
