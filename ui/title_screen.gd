extends Screen


signal game_mode_selected(game_mode: GameMode, fallback: bool)

@export var tutorial_game_mode: GameMode
@export var local_game_mode: GameMode
@export var multiplayer_game_mode: GameMode
@export var test_game_mode: GameMode

func _on_tutorial_button_pressed():
	game_mode_selected.emit(tutorial_game_mode, false)

func _on_local_game_button_pressed():
	game_mode_selected.emit(local_game_mode, false)

func _on_multiplayer_game_button_pressed():
	game_mode_selected.emit(multiplayer_game_mode, false)

func _on_fallback_multiplayer_game_button_pressed():
	game_mode_selected.emit(multiplayer_game_mode, true)


func _on_test_button_pressed():
	game_mode_selected.emit(test_game_mode, false)
