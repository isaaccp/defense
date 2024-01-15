extends Button

class_name ConfirmableButton

@export_multiline var confirmation_text: String
## Whether confirmation is required in this button.
@export var confirmation_required = true
var dialog: ConfirmationDialog

signal pressed_confirmed

func _ready():
	dialog = %ConfirmationDialog
	dialog.title = text
	dialog.dialog_text = confirmation_text

func _on_pressed():
	if confirmation_required:
		dialog.show()
	else:
		pressed_confirmed.emit()

func _on_confirmation_dialog_confirmed():
	pressed_confirmed.emit()

## So parent can decide whether confirmation is required.
func set_confirmation_required(confirmation_required: bool):
	self.confirmation_required = confirmation_required

## True if the dialog is currently shown.
func confirmation_visible() -> bool:
	return dialog.visible

## Hide dialog (for external callers).
func cancel_dialog():
	dialog.visible = false
