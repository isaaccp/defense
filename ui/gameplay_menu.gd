extends Control

class_name GameplayMenu

# Top level Control to block all input.
# Panel under it to add shade to background.

var state_machine_stack: StateMachineStack

signal save_and_quit_requested
signal reset_requested
signal abandon_run_requested
signal closed

func initialize(state_machine_stack: StateMachineStack):
	self.state_machine_stack = state_machine_stack

func enable(enabled: bool):
	visible = enabled
	set_process_input(enabled)
	if not enabled:
		return
	var run_sm = state_machine_stack.get_state_machine(Run.StateMachineName)
	# Unfortunately can't do checks using the variable names as they are not
	# accesibles to the class. Could create constant strings for each of them,
	# but it would be twice as many lines to define the states.
	%SaveAndQuitButton.visible = true
	%ResetLevelButton.visible = run_sm and run_sm.state.name == "within_level"
	%AbandonRunButton.visible = run_sm and not run_sm.state.name == "run_summary"

func _on_save_and_quit_button_pressed_confirmed():
	save_and_quit_requested.emit()
	enable(false)

func _on_reset_level_button_pressed_confirmed():
	reset_requested.emit()
	enable(false)

func _on_abandon_run_button_pressed_confirmed():
	abandon_run_requested.emit()
	enable(false)

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
