extends Screen


signal game_mode_selected(game_mode: GameMode)

@export var tutorial_game_mode: GameMode
@export var local_game_mode: GameMode
@export var multiplayer_game_mode: GameMode
@export var test_game_mode: GameMode

func _ready():
	for button in %GameModeButtons.get_children():
		assert(button is GameModeButton)
		button.pressed.connect(_on_game_mode_button_pressed.bind(button.game_mode))

func _on_game_mode_button_pressed(game_mode: GameMode):
	game_mode_selected.emit(game_mode)
