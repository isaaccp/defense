extends RefCounted

class_name Effect

## Emitted when ability to act is changed.
## Only subscribed to if AbleToAct is set in effect_types.
signal able_to_act(can_act: bool)

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

## Returns a modified action cooldown. The action_def is passed because some effects
## may only apply to certain actions or tags.
## logger should be used with a single-line of information describing the effect.
## If the method modifies the cooldown, it *must* call the logger.
func modified_action_cooldown(action_def: ActionDef, cooldown: float, logger: Callable = Callable()) -> float:
	assert(false, "Should be implemented in subclass if setting ACTION_COOLDOWN")
	return -1

func on_effect_removed():
	pass
