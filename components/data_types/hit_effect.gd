extends Resource

class_name HitEffect

## Damage on hit.
@export var damage: int
## Type of damage inflicted.
@export var damage_type: DamageType
## Fraction armor penetration. Ignore this fraction of armor.
@export var fraction_armor_pen: float
## Flat armor penetration. Ignore this much armor (applied after percentage).
@export var flat_armor_pen: int
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

@export_group("Internal - Do not set")
# Set by hitbox on hit, but exported so the object can be duplicated easily.
@export var action_name: StringName
@export var attack_type: AttackType
@export var damage_multiplier: float = 1.0

func adjusted_damage():
	return round(float(damage) * damage_multiplier)

func log_text() -> String:
	var damage_str = _damage_str()
	var status_str = _status_str()
	var effect_str = Utils.filter_and_join_strings([damage_str, status_str])
	return effect_str

func _damage_str() -> String:
	# TODO: Display armor penetration in some way.
	if not damage:
		return ""
	var hit_type = "healed" if damage < 0 else "hit"
	var abs_damage = abs(damage)
	var abs_adjusted_damage = abs(adjusted_damage())
	var damage_str = (
		str(abs_adjusted_damage) if abs_adjusted_damage == abs_damage
		else "%d (base) * %0.1f (mult)" % [abs_damage, damage_multiplier, abs_adjusted_damage]
	)
	var types = []
	if attack_type:
		types.append(attack_type.name)
	if damage_type:
		types.append(damage_type.name)
	if not types.is_empty():
		damage_str += " (%s)" % Utils.filter_and_join_strings(types)
	var armor_pen_strs = []
	if fraction_armor_pen > 0:
		armor_pen_strs.append("%d%" % (fraction_armor_pen * 100))
	if flat_armor_pen > 0:
		armor_pen_strs.append("%d" % flat_armor_pen)
	if not armor_pen_strs.is_empty():
		damage_str += " (armor pen: %s)" % Utils.filter_and_join_strings(armor_pen_strs)
	return "%s for %s" % [hit_type, damage_str]

func _status_str() -> String:
	if not status:
		return ""
	var if_damaged_str = ""
	if status_on_damage_only:
		if_damaged_str = " if hit causes damage"
	return "will apply %s (%0.1fs)%s" % [status.name, status_duration, if_damaged_str]
