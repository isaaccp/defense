@tool
extends Control

class_name BehaviorEditor

signal behavior_saved(behavior: StoredBehavior)
signal canceled

# First loaded behavior, so it can be restored through revert.
var original_behavior: StoredBehavior

func initialize(behavior: StoredBehavior, is_editor: bool):
	original_behavior = behavior
	load_behavior(original_behavior)
	if is_editor:
		%CancelButton.hide()

func load_behavior(behavior: StoredBehavior) -> void:
	%BehaviorEditorView.load_behavior(behavior)

func get_behavior() -> StoredBehavior:
	return %BehaviorEditorView.get_behavior()

func _on_save_button_pressed():
	var behavior = %BehaviorEditorView.get_behavior()
	if not behavior:
		# TODO: Show popup error.
		print("error")
	behavior_saved.emit(behavior)

func _on_cancel_button_pressed():
	canceled.emit()

func _on_revert_button_pressed():
	%BehaviorEditorView.load_behavior(original_behavior)
