extends UILayerBase

class_name UILayer

@export_group("Internal")
@export var title_screen: Screen
@export var match_screen: Screen
@export var ready_screen: Screen
@export var overlay_message: Label

var overlay_generation = 0

signal title_screen_game_mode_selected(game_mode: GameMode, fallback: bool)

signal ready_screen_ready_pressed

func show_message(message: String) -> void:
	overlay_message.text = message
	overlay_message.show()
	overlay_generation += 1
	var current_generation = overlay_generation
	await get_tree().create_timer(1.0).timeout
	if current_generation == overlay_generation:
		overlay_message.hide()

func hide_message() -> void:
	overlay_message.hide()

func _on_title_screen_game_mode_selected(game_mode: GameMode, fallback: bool):
	title_screen_game_mode_selected.emit(game_mode, fallback)

func _on_ready_screen_ready_pressed():
	ready_screen_ready_pressed.emit()
