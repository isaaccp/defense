extends RefCounted

class_name Stat

const EnemiesDestroyed: StringName = &"enemies_destroyed"
const DamageDealt: StringName = &"damage_dealt"

var name: StringName
var value: Variant

func _init(name: StringName, value: Variant):
	self.name = name
	self.update = value
