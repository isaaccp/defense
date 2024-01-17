extends Resource

class_name Stat

# TODO: If needed, consider some type of check to make
# sure a level stats object only can get level stats,
# a run stats object can get level or run stats, etc.

# Level Stats.
const EnemiesDestroyed: StringName = &"enemies_destroyed"
const DamageDealt: StringName = &"damage_dealt"
const DamageHealed: StringName = &"damage_healed"

# Run Stats.
const LevelsBeaten: StringName = &"levels_beaten"

@export var name: StringName
@export var int_value: IntValue
@export var float_value: FloatValue

var value: Variant:
	get:
		if int_value:
			return int_value.value
		else:
			return float_value.value

static func make(name: StringName, value: Variant) -> Stat:
	var stat = Stat.new()
	stat.name = name
	if typeof(value) == TYPE_INT:
		stat.int_value = IntValue.make(value)
	elif typeof(value) == TYPE_FLOAT:
		stat.float_value = FloatValue.make(value)
	return stat

