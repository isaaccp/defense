extends Screen

signal continue_selected

func _on_show(info: Dictionary):
	%Title.text = info.get("title", "Brief Respite")
	%ContentLabel.text = info.text

func _on_continue_button_pressed():
	continue_selected.emit()
