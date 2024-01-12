extends Resource

class_name Attributes

## Movement speed.
@export var speed: float
## Max health.
@export var health: int
## Multiplier applied to damage.
@export var damage_multiplier: float = 1.0
## Flat amount removed from physical attacks.
@export var armor: int = 0
## Resistances. See Resistance definition.

@export var resistance: Array[Resistance]
