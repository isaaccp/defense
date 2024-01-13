extends Container

signal restart_pressed
signal play_pressed
signal pause_pressed

var hud: Hud
var speeds = [1, 2, 0.5]
var current_speed = 0

func initialize(hud_: Hud):
	hud = hud_

func _pause(pause: bool = true):
	if pause:
		pause_pressed.emit()
	else:
		play_pressed.emit()

func _on_stop_button_pressed():
	# TODO: pause.
	%RestartDialog.show()

func _on_pause_button_pressed():
	if hud:
		hud.show_main_message("Paused", 1.0)
	%PlayButton.show()
	%PauseButton.hide()
	_pause()

func _on_play_button_pressed():
	if hud:
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

func _on_visibility_changed():
	# Ensure that we restore time scale if hidden.
	Engine.time_scale = 1.0
	if visible:
		Engine.time_scale = speeds[current_speed]

func _on_speed_button_pressed():
	current_speed = (current_speed + 1) % speeds.size()
	Engine.time_scale = speeds[current_speed]
	%SpeedButton/Label.text = _speed_string(speeds[current_speed])

func _speed_string(speed: float) -> String:
	if speed >= 1:
		return "%1.0fx" % speed
	else:
		return ("%.1fx" % speed).lstrip("0")
