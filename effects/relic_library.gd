extends Resource

class_name RelicLibrary

@export var relics: Array[RelicDef]:
	set(value):
		relics = value
		_index()

var relic_by_name: Dictionary

func _index():
	for relic in relics:
		relic_by_name[relic.name] = relic

func get_relic(relic: StringName) -> RelicDef:
	return relic_by_name[relic] as RelicDef

func lookup_relics(relic_names: Array[StringName]) -> Array[RelicDef]:
	var found_relics: Array[RelicDef] = []
	for relic_name in relic_names:
		found_relics.append(get_relic(relic_name))
	return found_relics
