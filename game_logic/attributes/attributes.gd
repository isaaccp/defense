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

func _to_string():
	for property in get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			print("%s: %s" % [property.name, get(property.name)])
