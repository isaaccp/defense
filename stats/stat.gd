extends RefCounted

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

var name: StringName
var value: Variant

func _init(name: StringName, value: Variant):
	self.name = name
	self.value = value
