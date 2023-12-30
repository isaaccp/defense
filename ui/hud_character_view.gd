extends Control

class_name HudCharacterView

var character: Character

signal configure_behavior_selected
signal readiness_updated(ready: bool)

func _ready():
	%ConfigContainer.hide()
	
func initialize(character_: Character) -> void:
	character = character_
	%Title.text = character.short_name()

func is_local() -> bool:
	if OnlineMatch.match_mode == OnlineMatch.MatchMode.NONE:
		return true
	var multiplayer_id = multiplayer.get_unique_id()
	return multiplayer_id == character.peer_id
	
func show_config(show: bool) -> void:
	if show:
		if is_local():
			%ConfigContainer.show()
	else:
		%ConfigContainer.hide()

func _on_configure_behavior_button_pressed():
	configure_behavior_selected.emit()

func _on_ready_button_toggled(toggled_on: bool):
	readiness_updated.emit(toggled_on)
