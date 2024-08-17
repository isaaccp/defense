extends Resource

class_name RelicLibraryState

# TODO: Probably at some point need to figure out some way to unlock those
# rather than having all of them available from start.
# Maybe just more meta skills.
@export var available_relics: Array[StringName]
# Relics that will be offered next time.
@export var next_relic_selection: Array[StringName]

static func from_relic_library(relic_library: RelicLibrary):
	var relic_library_state = RelicLibraryState.new()
	if relic_library:
		relic_library_state.initialize(relic_library)
	return relic_library_state

func initialize(relic_library: RelicLibrary):
	for relic in relic_library.relics:
		available_relics.append(relic.name)

func select_relics(number: int):
	next_relic_selection = []
	if len(available_relics) <= number:
		for relic in available_relics:
			next_relic_selection.append(relic)
		return
	var relics_copy = available_relics.duplicate()
	for i in range(number):
		var idx = randi() % relics_copy.size()
		var relic = relics_copy[idx]
		relics_copy.remove_at(idx)
		next_relic_selection.append(relic)

func selected_relics() -> Array[StringName]:
	return next_relic_selection

func clear_relic_selection():
	next_relic_selection = []

func mark_relic_used(relic: StringName):
	for i in range(len(available_relics)):
		if available_relics[i] == relic:
			available_relics.remove_at(i)
			return
	assert(false, "Failed to find relic to mark as used")
