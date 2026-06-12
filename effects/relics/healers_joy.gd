extends Effect

# Priest class/universal relic. +1 max HP per 100 health healed, per-character counter.
# Identity: "healer's joy grows with the vitality of allies."

const HEAL_THRESHOLD = 100
const MAX_HP_BONUS_PER_THRESHOLD = 1

func modify_attributes(base_attributes: Attributes) -> void:
	var healed_so_far = persistent_state.get("healed_so_far", 0)
	var bonus_hp = (healed_so_far / HEAL_THRESHOLD) * MAX_HP_BONUS_PER_THRESHOLD
	base_attributes.health += bonus_hp

func on_heal_applied(amount_healed: int, _target_name: String) -> void:
	var old_healed = persistent_state.get("healed_so_far", 0)
	var new_healed = old_healed + amount_healed
	persistent_state["healed_so_far"] = new_healed

	var old_bonus = (old_healed / HEAL_THRESHOLD) * MAX_HP_BONUS_PER_THRESHOLD
	var new_bonus = (new_healed / HEAL_THRESHOLD) * MAX_HP_BONUS_PER_THRESHOLD

	if new_bonus > old_bonus:
		var actuator = Component.get_or_null(bearer, EffectActuatorComponent.component) as EffectActuatorComponent
		if actuator:
			actuator.attribute_effects_changed.emit()
