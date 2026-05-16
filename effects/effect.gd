extends RefCounted

class_name Effect

## Emitted when ability to act is changed.
## Only subscribed to if AbleToAct is set in effect_types.
signal able_to_act(can_act: bool)

## The actor this effect is attached to. Set by EffectActuatorComponent when
## the effect is added. Used by event-hook effects (e.g. focus-regen relics)
## that need to read/modify the bearer's components.
var bearer: Node

func initialize(params: EffectParams) -> void:
	pass

func on_effect_added():
	pass

# TODO: Consider making all those return a bool specifying if they modified something or not.
# Then invoking classes could provide the logger themselves instead of passing it through from
# users and that could verify that the logger is always called if the method returns bool.
# That would ensure that we don't miss modifications in logs.
## Modifies attributes in-place. Caller is responsible for ensuring they make a copy beforehand.
## Only called if Attribute is set in effect_types.
func modify_attributes(_base_attributes: Attributes) -> void:
	assert(false, "Should be implemented in subclass if setting Attribute")

## Modifies hit_effect in-place. Caller is responsible for ensuring they make a copy beforehand.
## Only called if HIT_EFFECT is set in effect_types.
## logger should be used with a single-line of information describing the effect.
## If the method modifies the hit_effect, it *must* call the logger at least once.
func modify_hit_effect(_hit_effect: HitEffect, logger: Callable = Callable()) -> void:
	assert(false, "Should be implemented in subclass if setting HIT_EFFECT")

## Returns a modified action cooldown. The action def is passed because some effects
## may only apply to certain tags.
## logger should be used with a single-line of information describing the effect.
## If the method modifies the cooldown, it *must* call the logger.
func modified_action_cooldown(action_def: ActionDef, cooldown: float, logger: Callable = Callable()) -> float:
	assert(false, "Should be implemented in subclass if setting ACTION_COOLDOWN")
	return -1

## Called when the bearer takes damage. Only invoked if ON_DAMAGE_TAKEN is in effect_types.
## `damage_taken` is the final damage that landed (after armor/resistances).
## `attacker_name` is the actor_name of whoever dealt the hit.
func on_damage_taken(_damage_taken: int, _attacker_name: String) -> void:
	assert(false, "Should be implemented in subclass if setting ON_DAMAGE_TAKEN")

## Called when the bearer applies a heal to an ally (or self). Only invoked if
## ON_HEAL_APPLIED is in effect_types. `amount_healed` is the actual HP restored.
func on_heal_applied(_amount_healed: int, _target_name: String) -> void:
	assert(false, "Should be implemented in subclass if setting ON_HEAL_APPLIED")

## Called when the bearer kills an enemy. Only invoked if ON_ENEMY_KILLED is in effect_types.
func on_enemy_killed(_victim_name: String) -> void:
	assert(false, "Should be implemented in subclass if setting ON_ENEMY_KILLED")

func on_effect_removed():
	pass
