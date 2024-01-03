extends Container

signal restart_pressed
signal play_pressed
signal pause_pressed

func _pause(pause: bool = true):
	get_tree().paused = pause

func _on_stop_button_pressed():
	# TODO: pause.
	%RestartDialog.show()

func _on_pause_button_pressed():
	%PlayButton.show()
	%PauseButton.hide()
	_pause()

func _on_play_button_pressed():
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
