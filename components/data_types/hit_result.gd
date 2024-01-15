extends Resource

class_name HitResult

## Damage/heal inflicted.
@export var damage: int
## Type of damage inflicted.
@export var damage_type: DamageType
## Destroyed enemy.
@export var destroyed: bool
# Status on hit.
## Status inflicted, if any.
@export var status: StatusDef.Id

func stats_update() -> Array[Stat]:
	var updates: Array[Stat] = []
	if damage > 0:
		updates.append(Stat.new(Stat.DamageDealt, damage))
	elif damage < 0:
		updates.append(Stat.new(Stat.DamageHealed, -damage))
	# TODO: Status.
	# TODO: Damage per damage type.
	if destroyed:
		updates.append(Stat.new(Stat.EnemiesDestroyed, 1))
	return updates

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
	return "%s for %d" % [hit_type, abs_damage]

func _status_str() -> String:
	if status == StatusDef.Id.UNSPECIFIED:
		return ""
	return "applied %s" % [StatusDef.name(status)]
