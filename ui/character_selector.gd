extends Container

@export var label: Label
@export var options: Container

const rich_button_scene = preload("res://ui/rich_button.tscn")

signal character_selected(character_id: Enum.CharacterId)

var player_id: int

func initialize(_player_id: int):
	player_id = _player_id

func _ready():
	label.text = "Player %d" % player_id
	for character_id in CharacterManager.available_characters():
		var character_name = CharacterManager.character_name(character_id)
		var description = CharacterManager.description(character_id)
		var button = rich_button_scene.instantiate()
		button.set_meta("character_id", character_id)
		button.label_text = "[b][center]%s[/center][/b]\n%s" % [
			character_name, description]
		button.pressed.connect(_character_selected.bind(button, character_id))
		options.add_child(button)

func _character_selected(button: Button, character_id: Enum.CharacterId):
	character_selected.emit(character_id)

func disable_and_show_selection(character_id: Enum.CharacterId):
	for child in options.get_children():
		child.disabled = true
		if child.get_meta("character_id") == character_id:
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
