extends Control

signal play_next_selected
signal try_again_selected

func prepare(win: bool, character_node: Node, granted_xp_text: String):
	%LevelSummary.prepare(character_node)
	%PlayNextButton.visible = win
	%TryAgainButton.set_confirmation_required(win)
	%XPLabel.visible = true
	%XPLabel.text = granted_xp_text

func _on_play_next_button_pressed():
	play_next_selected.emit()
	hide()

func _on_try_again_button_pressed_confirmed():
	try_again_selected.emit()
	hide()
