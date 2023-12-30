extends Control

class_name HudCharacterView

@export var title: Label
@export var configure_behavior_button: Button

var character: Character

signal configure_behavior_selected

func initialize(character_: Character) -> void:
	character = character_
	title.text = character.short_name()

func is_local() -> bool:
	if OnlineMatch.match_mode == OnlineMatch.MatchMode.NONE:
		return true
	var multiplayer_id = multiplayer.get_unique_id()
	return multiplayer_id == character.peer_id
	
func show_config(show: bool) -> void:
	if show:
		if is_local():
			configure_behavior_button.show()
	else:
		configure_behavior_button.hide()

func _on_configure_behavior_button_pressed():
	configure_behavior_selected.emit()
