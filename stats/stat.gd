extends RefCounted

class_name Stat

const EnemiesDestroyed: StringName = &"enemies_destroyed"
const DamageDealt: StringName = &"damage_dealt"
const DamageHealed: StringName = &"damage_healed"

var name: StringName
var value: Variant

func _init(name: StringName, value: Variant):
	self.name = name
	self.value = value
