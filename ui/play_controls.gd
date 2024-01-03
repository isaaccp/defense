extends Container

signal restart_pressed
signal play_pressed
signal pause_pressed

var hud: Hud

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
