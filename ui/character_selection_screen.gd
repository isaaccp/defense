extends Screen

class_name CharacterSelectionScreen

@export var characters_container: Container

const character_selector_scene = preload("res://ui/character_selector.tscn")

signal selection_ready(character_selections: Array[Enum.CharacterId])

var sorted_players: Array
var selections = {}
var selections_wanted: int

func set_characters(num_characters: int) -> void:
	selections_wanted = num_characters

func _on_show(info: Dictionary = {}) -> void:
	sorted_players = OnlineMatch.get_sorted_players()
	clear_characters()
	# Character 0 controls (character_idx % num_players) == 0, and so on.
	for selection in range(selections_wanted):
		add_character(selection, sorted_players[selection%sorted_players.size()].session_id)

func clear_characters() -> void:
	for child in characters_container.get_children():
		characters_container.remove_child(child)
		child.queue_free()

func add_character(character_idx: int, session_id: String) -> void:
	var character_selector = character_selector_scene.instantiate()
	character_selector.name = session_id
	character_selector.initialize(character_idx)
	characters_container.add_child(character_selector)
	if session_id == "local" or session_id == OnlineMatch.get_my_session_id():
		character_selector.character_selected.connect(_on_character_selected.bind(character_idx))
	else:
		character_selector.enable(false)

func _on_character_selected(character_id: Enum.CharacterId, character_idx: int):
	_notify_selection.rpc(character_idx, character_id)

@rpc("any_peer", "call_local")
func _notify_selection(character_idx: int, character_id: Enum.CharacterId):
	selections[character_idx] = character_id
	if sorted_players.is_empty() or selections.size() == selections_wanted:
		var selection_array: Array[Enum.CharacterId] = []
		for i in range(selections.size()):
			selection_array.append(selections[i] as Enum.CharacterId)
		selection_ready.emit(selection_array)
	else:
		var character_container = characters_container.get_child(character_idx)
		character_container.disable_and_show_selection(character_id)

# For testing.
func character_selector_count() -> int:
	return characters_container.get_child_count()

func character_selector(i: int) -> CharacterSelector:
	return characters_container.get_child(i)
