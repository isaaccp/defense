extends Resource

class_name Resistance

## AttackType and DamageType this resistance applies to. If either is None,
## it applies to all types.
@export var attack_type: AttackType
@export var damage_type: DamageType
## Amount of resistance as a percentage.
## * A positive number means damage applied is reduced by that %-age.
## * A negative number means damage applied is increased by that %-age.
@export_range(-100,100) var percentage: int = 0

func applies_to(a_type: AttackType, d_type: DamageType) -> bool:
	if attack_type != null and attack_type != a_type:
		return false
	if damage_type != null and damage_type != d_type:
		return false
	return true
