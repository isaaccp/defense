extends Effect

# Bow Attack damage is converted to fire damage.
# Pairs with Pyromancer's Mark for a ranged-fire build.

const fire_damage_type = preload("res://game_logic/damage_types/fire.tres")
const bow_attack_def = preload("res://skill_tree/actions/bow_attack.tres")

func modify_hit_effect(hit_effect: HitEffect, _target: Node, logger: Callable = Callable()) -> void:
	if hit_effect.action_name != bow_attack_def.skill_name:
		return
	if hit_effect.damage_type == fire_damage_type:
		return
	hit_effect.damage_type = fire_damage_type
	logger.call("Igniter Quiver converted Bow Attack to fire damage")
