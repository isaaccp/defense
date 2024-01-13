extends Button

class_name ConfirmableButton

@export_multiline var confirmation_text: String

var dialog: ConfirmationDialog

signal pressed_confirmed

func _ready():
	dialog = %ConfirmationDialog
	dialog.title = text
	dialog.dialog_text = confirmation_text

func _on_pressed():
	dialog.show()

func _on_confirmation_dialog_confirmed():
	pressed_confirmed.emit()

## True if the dialog is currently shown.
func confirmation_visible() -> bool:
	return dialog.visible

## Hide dialog (for external callers).
func cancel_dialog():
	dialog.visible = false
