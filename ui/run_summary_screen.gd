extends Screen

class_name RunSummaryScreen

signal continue_selected

func _on_show(info: Dictionary):
	%SummaryTextLabel.text = info.text

func _on_continue_button_pressed():
	continue_selected.emit()
