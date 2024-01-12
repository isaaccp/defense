extends Resource

class_name Resistance

## Damage Type this resistance applies to.
@export var damage_type: DamageType
## Amount of resistance as a percentage.
## * A positive number means damage applied is reduced by that %-age.
## * A negative number means damage applied is increased by that %-age.
@export_range(-100,100) var percentage: int = 0
