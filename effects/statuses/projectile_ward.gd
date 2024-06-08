extends Effect

const ranged_attack = preload("res://game_logic/attack_types/ranged.tres")

func modify_attributes(attributes: Attributes) -> void:
	var resistance = Resistance.new()
	resistance.percentage = 50
	resistance.attack_type = ranged_attack
	attributes.add_resistance(resistance)
