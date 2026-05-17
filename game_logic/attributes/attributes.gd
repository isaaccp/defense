@tool
extends Resource

class_name Attributes

## Movement speed.
@export var speed: float
## Max health.
@export var health: int
## Fraction of health recovered at end of level. Flat across all characters by design —
## see BALANCE.md ("recovery" row) before adding per-character overrides.
@export var recovery: float = 0.25
## Max focus.
@export var focus: int
## Focus regen per second.
@export var focus_regen: float
## In-combat HP regen per second. Default 0; raised by relics like Regeneration Ring.
@export var health_regen: float = 0.0
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

func _to_string() -> String:
	var attr_str = ""
	for property in get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			attr_str += "%s: %s\n" % [property.name, get(property.name)]
	return attr_str
	
