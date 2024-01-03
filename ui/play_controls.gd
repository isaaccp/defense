extends Container

signal restart_pressed
signal play_pressed
signal pause_pressed

func _on_play_pause_button_toggled(toggled_on):
	pass # Replace with function body.

func _on_stop_button_pressed():
	# TODO: pause.
	%RestartDialog.show()

func _on_restart_dialog_confirmed():
	restart_pressed.emit()
	print("restart confirmed")
