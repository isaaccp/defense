extends Resource

class_name RelicLibrary

@export var relics: Array[RelicDef]:
	set(value):
		relics = value
		available_relics = relics
		_index()

# TODO: Probably at some point need to figure out some way to unlock those
# rather than having all of them available from start.
# Maybe just more meta skills.
@export var available_relics: Array[RelicDef]

var relic_by_name: Dictionary

func _index():
	for relic in relics:
		relic_by_name[relic.name] = relic

func get_relic(relic: StringName) -> RelicDef:
	return relic_by_name[relic] as RelicDef

func select_relics(number: int) -> Array[RelicDef]:
	if len(available_relics) <= number:
		return available_relics
	var relics_copy = available_relics.duplicate()
	var selected_relics: Array[RelicDef] = []
	for i in range(number):
		var idx = randi() % relics_copy.size()
		var relic = relics_copy[idx]
		relics_copy.remove_at(idx)
		selected_relics.append(relic)
	return selected_relics

func mark_relic_used(relic: StringName):
	for i in range(len(available_relics)):
		if available_relics[i].name == relic:
			available_relics.remove_at(i)
			return
	assert(false, "Failed to find relic to mark as used")
