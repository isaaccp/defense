extends Control

class_name GameplayMenu

# Top level Control to block all input.
# Panel under it to add shade to background.

signal save_and_quit_requested
signal reset_requested
signal closed

func enable(enabled: bool):
	visible = enabled
	set_process_input(enabled)

func _on_save_and_quit_button_pressed_confirmed():
	save_and_quit_requested.emit()

func _on_reset_level_button_pressed_confirmed():
	reset_requested.emit()

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		var cancel_processed = false
		# See if there are any dialogs open, if so,
		# cancel should just close it.
		for button in %Buttons.get_children():
			if not button is ConfirmableButton:
				continue
			var cb = button as ConfirmableButton
			if cb.confirmation_visible():
				cb.cancel_dialog()
				cancel_processed = true
				break
		# If no dialogs were opened, escape should
		# close this menu instead.
		if not cancel_processed:
			enable(false)
		get_viewport().set_input_as_handled()
		closed.emit()
