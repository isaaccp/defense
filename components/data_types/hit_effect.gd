extends Resource

class_name HitEffect

## Damage on hit.
@export var damage: int
## Type of damage inflicted.
@export var damage_type: DamageType
# Status on hit.
## Status inflicted, if any.
@export var status: StatusDef
## Duration for status.
@export var status_duration: float
## Whether status only gets inflicted if hit causes damage
## (set to true for e.g. poison attack with a weapon).
## Defaults to false as HitEffect is also used for Status-only
## effects.
@export var status_on_damage_only = false

# Set by hitbox on hit.
var action_name: StringName
var attack_type: AttackType
var damage_multiplier: float = 1.0

func adjusted_damage():
	return round(float(damage) * damage_multiplier)

func log_text() -> String:
	var damage_str = _damage_str()
	var status_str = _status_str()
	var effect_str = Utils.filter_and_join_strings([damage_str, status_str])
	return effect_str

func _damage_str() -> String:
	if not damage:
		return ""
	var hit_type = "healed" if damage < 0 else "hit"
	var abs_damage = abs(damage)
	var abs_adjusted_damage = abs(adjusted_damage())
	var damage_str = (
		str(abs_adjusted_damage) if abs_adjusted_damage == abs_damage
		else "[hint=%d (base) * %0.1f (mult)]%d[/hint]" % [abs_damage, damage_multiplier, abs_adjusted_damage]
	)
	return "%s for %s" % [hit_type, damage_str]

func _status_str() -> String:
	if not status:
		return ""
	return "applied %s (%0.1fs)" % [status.name, status_duration]
