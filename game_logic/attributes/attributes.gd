@tool
extends Resource

class_name Attributes

## Movement speed.
@export var speed: float
## Max health.
@export var health: int
## Fraction of health recovered at end of level.
@export var recovery: float
## Multiplier applied to damage.
@export var damage_multiplier: float = 1.0
## Flat amount removed from physical attacks.
@export var armor: int = 0
## Resistances. See Resistance definition.
@export var resistance: Array[Resistance]

func add_resistance(added_res: Resistance):
	for res in resistance:
		if res.attack_type == added_res.attack_type and res.damage_type == added_res.damage_type:
			res.percentage += added_res.percentage
			return
	resistance.append(added_res)

func resistance_multiplier_for(attack_type: AttackType, damage_type: DamageType) -> float:
	var percentage = 0
	for r in resistance:
		if r.applies_to(attack_type, damage_type):
			percentage += r.percentage
	return (100-percentage) / 100.0

func _to_string():
	for property in get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			print("%s: %s" % [property.name, get(property.name)])
