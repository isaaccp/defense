extends Screen

signal continue_selected

func _on_show(info: Dictionary):
	%ContentLabel.text = info.text

func _on_continue_button_pressed():
	continue_selected.emit()
