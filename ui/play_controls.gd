extends Container

signal restart_pressed
signal play_pressed
signal pause_pressed

var hud: Hud

func _ready():
	if not %DoubleSpeedButton.button_pressed:
		%DoubleSpeedButton.modulate = Color(1, 1, 1, 0.5)

func initialize(hud_: Hud):
	hud = hud_

func _pause(pause: bool = true):
	get_tree().paused = pause

func _on_stop_button_pressed():
	# TODO: pause.
	%RestartDialog.show()

func _on_pause_button_pressed():
	hud.show_main_message("Paused", 1.0)
	%PlayButton.show()
	%PauseButton.hide()
	_pause()

func _on_play_button_pressed():
	hud.hide_main_message()
	%PlayButton.hide()
	%PauseButton.show()
	_pause(false)

func _on_restart_button_pressed():
	_pause()
	%RestartDialog.show()

func _on_restart_dialog_confirmed():
	_pause(false)
	restart_pressed.emit()

func _on_restart_dialog_canceled():
	_pause(false)

func _on_double_speed_button_toggled(toggled_on):
	if toggled_on:
		%DoubleSpeedButton.modulate = Color.WHITE
		Engine.time_scale = 2.0
	else:
		%DoubleSpeedButton.modulate = Color(1, 1, 1, 0.5)
		Engine.time_scale = 1.0

func _on_visibility_changed():
	# Ensure that we restore time scale if hidden.
	Engine.time_scale = 1.0
	if visible and %DoubleSpeedButton.button_pressed:
		Engine.time_scale = 2.0
