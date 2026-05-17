extends Effect

# Priest starting bonus relic. Targeted ranged resistance — addresses the
# common archer-pressure failure mode where the cleric melts to ranged attacks.
# Does not affect melee, so she's not generally tankier.

const ranged_attack = preload("res://game_logic/attack_types/ranged.tres")
const RANGED_RESISTANCE_PCT: int = 50

func modify_attributes(attributes: Attributes) -> void:
	var resistance = Resistance.new()
	resistance.percentage = RANGED_RESISTANCE_PCT
	resistance.attack_type = ranged_attack
	attributes.add_resistance(resistance)
