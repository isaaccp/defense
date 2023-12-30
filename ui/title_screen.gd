extends Screen

signal local_selected
signal connect_selected(fallback: bool)

func _on_local_game_button_pressed():
	local_selected.emit()

func _on_multiplayer_game_button_pressed():
	connect_selected.emit(false)

func _on_fallback_multiplayer_game_button_pressed():
	connect_selected.emit(true)
