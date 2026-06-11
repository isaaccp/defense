extends Effect

# Sword Attack damage is converted to fire damage.
# Pairs with Pyromancer's Mark for a melee-fire build.

const fire_damage_type = preload("res://game_logic/damage_types/fire.tres")
const sword_attack_def = preload("res://skill_tree/actions/sword_attack.tres")

func modify_hit_effect(hit_effect: HitEffect, _target: Node, logger: Callable = Callable()) -> void:
	if hit_effect.action_name != sword_attack_def.skill_name:
		return
	if hit_effect.damage_type == fire_damage_type:
		return  # already fire — nothing to convert
	hit_effect.damage_type = fire_damage_type
	logger.call("Ember Brand converted Sword Attack to fire damage")
