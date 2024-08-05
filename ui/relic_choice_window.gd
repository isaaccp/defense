extends Window

class_name RelicChoiceWindow

const rich_button_scene = preload("res://ui/rich_button.tscn")

var selected_relic: StringName

signal relic_selected(relic_name: StringName, gc: GameplayCharacter)
signal relic_selection_canceled

func initialize(relics: Array[RelicDef], characters: Array[GameplayCharacter]):
	%RelicSelectionContainer.visible = true
	%CharacterSelectionContainer.visible = false
	var min_size = Vector2(300, 250)
	for relic in relics:
		var button = rich_button_scene.instantiate()
		var description = "[b][center]%s[/center][/b]\n" % relic.name
		description += relic.description
		button.label_text = description
		button.pressed.connect(_relic_selected.bind(relic.name))
		button.custom_minimum_size = min_size
		%RelicContainer.add_child(button)
	for character in characters:
		var button = rich_button_scene.instantiate()
		var description = "[b][center]%s[/center][/b]\n" % character.name
		button.label_text = description
		button.pressed.connect(_character_selected.bind(character))
		button.custom_minimum_size = min_size
		%CharacterContainer.add_child(button)

func _relic_selected(relic_name: StringName):
	selected_relic = relic_name
	%RelicSelectionContainer.visible = false
	%CharacterSelectionContainer.visible = true

func _character_selected(gc: GameplayCharacter):
	relic_selected.emit(selected_relic, gc)
	queue_free()

func _on_cancel_button_pressed():
	relic_selection_canceled.emit()
	queue_free()
