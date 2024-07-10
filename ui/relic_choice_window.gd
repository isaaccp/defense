extends Window

class_name RelicChoiceWindow

const rich_button_scene = preload("res://ui/rich_button.tscn")

signal relic_selected(relic_name: StringName)
signal relic_selection_canceled

func initialize(relics: Array[RelicDef]):
	for relic in relics:
		var button = rich_button_scene.instantiate()
		var description = "[b][center]%s[/center][/b]\n" % relic.name
		description += relic.description
		button.label_text = description
		button.pressed.connect(_relic_selected.bind(relic.name))
		button.custom_minimum_size = Vector2(300, 250)
		%RelicContainer.add_child(button)

func _relic_selected(relic_name: StringName):
	# TODO: After we select relic we need to decide for which character it is.
	# Probably the easiest way is to just have another set of controls in this
	# window that allows to select character and directly emit here both
	# the relic_name and the character that was chosen.
	relic_selected.emit(relic_name)
	queue_free()

func _on_cancel_button_pressed():
	relic_selection_canceled.emit()
	queue_free()
