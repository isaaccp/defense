extends RefCounted

class_name Effect

## Emitted when ability to act is changed.
## Only subscribed to if AbleToAct is set in effect_types.
signal able_to_act(can_act: bool)

func on_effect_added():
	pass

## Modifies attributes in-place. Caller is responsible for ensuring they make a copy beforehand.
## Only called if Attribute is set in effect_types.
func modify_attributes(_base_attributes: Attributes) -> void:
	assert(false, "Should be implemented in subclass if setting Attribute")

## Modifies hit_effect in-place. Caller is responsible for ensuring they make a copy beforehand.
## Only called if HIT_EFFECT is set in effect_types.
func modify_hit_effect(_hit_effect: HitEffect) -> void:
	assert(false, "Should be implemented in subclass if setting HIT_EFFECT")

func on_effect_removed():
	pass
