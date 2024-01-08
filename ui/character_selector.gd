extends Container

class_name CharacterSelector

@export var options: Container

const rich_button_scene = preload("res://ui/rich_button.tscn")

signal character_selected(character_idx: int)

var player_id: int
var available_characters: Array[GameplayCharacter]

func initialize(player_id_: int, available_characters_: Array[GameplayCharacter]):
	player_id = player_id_
	available_characters = available_characters_

func _ready():
	%Label.text = "Player %d" % player_id
	for i in range(available_characters.size()):
		var character = available_characters[i]
		var description = _description(character)
		var button = rich_button_scene.instantiate()
		button.set_meta("character_idx", i)
		button.label_text = description
		button.pressed.connect(_character_selected.bind(button, i))
		options.add_child(button)

func _description(character: GameplayCharacter) -> String:
	var description = ""
	description += "[b][center]%s[/center][/b]\n" % character.name
	description += "Starting kit: %s\n" % character.starting_kit
	description += "%s\n" % character.description
	return description

func _character_selected(_button: Button, character_idx: int):
	character_selected.emit(character_idx)

func disable_and_show_selection(character_idx: int):
	for child in options.get_children():
		child.disabled = true
		if child.get_meta("character_idx") == character_idx:
			child.modulate = Color(1, 1, 1, 0.9)
		else:
			child.modulate = Color(1, 1, 1, 0.1)

func enable(enabled: bool):
	for child in options.get_children():
		child.disabled = !enabled
		if enabled:
			child.modulate = Color(1, 1, 1, 1)
		else:
			child.modulate = Color(1, 1, 1, 0.75)
