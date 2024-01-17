@tool
extends Control

class_name BehaviorLibraryUI

# Initialized from outside.
var behavior_library: BehaviorLibrary
var behavior_editor: BehaviorEditor

# Internal.
@onready var save_to_library_dialog: AcceptDialog = %SaveBehaviorNameDialog
@onready var behavior_name_line_edit: LineEdit = %BehaviorNameLineEdit
var behavior_list: ItemList
# Name of the behavior selected when we show a popup.
var popup_name: String

signal behavior_activated(behavior: StoredBehavior)

func initialize(behavior_library: BehaviorLibrary, behavior_editor: BehaviorEditor):
	self.behavior_library = behavior_library
	self.behavior_editor = behavior_editor

func _ready():
	behavior_list = %Behaviors
	save_to_library_dialog.register_text_enter(behavior_name_line_edit)
	refresh()

func refresh():
	%Behaviors.clear()
	if not behavior_library:
		return
	for behavior in behavior_library.behaviors:
		%Behaviors.add_item(behavior.name)
		# TODO: Implement filtering.

func get_selected() -> StoredBehavior:
	var items = %Behaviors.get_selected_items()
	if items.size() == 0:
		return null
	else:
		return behavior_library.behaviors[items[0]]

func _on_behaviors_item_activated(index: int):
	behavior_activated.emit(behavior_library.behaviors[index])

func _on_behaviors_item_clicked(index: int, at_position: Vector2, mouse_button_index: int):
	if mouse_button_index != MouseButton.MOUSE_BUTTON_RIGHT:
		return
	%PopupMenu.show()
	%PopupMenu.position = at_position + %Behaviors.global_position
	popup_name = behavior_library.behaviors[index].name

func _on_popup_menu_id_pressed(id: int):
	if id == 0:
		behavior_library.delete(popup_name)
		refresh()

func _on_save_to_library_button_pressed():
	save_to_library_dialog.show()
	var selected_behavior = get_selected()
	behavior_name_line_edit.text = selected_behavior.name if selected_behavior else ""
	behavior_name_line_edit.grab_focus()
func _on_save_behavior_name_dialog_confirmed():
	var behavior_name = behavior_name_line_edit.text
	var behavior = behavior_editor.get_behavior()
	behavior.name = behavior_name
	assert(not behavior_name.is_empty())
	if behavior_library.contains(behavior_name):
		behavior_library.replace(behavior)
	else:
		behavior_library.add(behavior)
	refresh()

func _on_behavior_activated(behavior: StoredBehavior):
	behavior_editor.load_behavior(behavior)
