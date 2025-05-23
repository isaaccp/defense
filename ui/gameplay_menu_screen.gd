extends Screen

signal new_run
signal continue_run

# TODO: Allow to abandon run from this menu, instead of having to continue
# and then abandon.
func _on_show(info: Dictionary):
	%NewRunButton.visible = not info.existing_run
	%ContinueRunButton.visible = info.existing_run

func _on_continue_run_button_pressed():
	continue_run.emit()

func _on_new_run_button_pressed():
	new_run.emit()
