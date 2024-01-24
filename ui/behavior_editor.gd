@tool
extends Control

class_name BehaviorEditor

signal behavior_saved(behavior: StoredBehavior)
signal canceled
signal can_save_to_behavior_library_updated(can_save: bool)

# First loaded behavior, so it can be restored through revert.
var original_behavior: StoredBehavior

func initialize(behavior: StoredBehavior, acquired_skills: SkillTreeState, is_editor: bool):
	original_behavior = behavior
	%BehaviorEditorView.initialize(acquired_skills)
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

func _on_behavior_editor_view_can_save_to_behavior_updated(can_save: bool):
	%SaveButton.disabled = not can_save

func _on_behavior_editor_view_can_save_to_behavior_library_updated(can_save: bool):
	can_save_to_behavior_library_updated.emit(can_save)
