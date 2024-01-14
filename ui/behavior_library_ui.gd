extends Control

class_name BehaviorLibraryUI

var behavior_library: BehaviorLibrary
var behavior_list: ItemList
# Name of the behavior selected when we show a popup.
var popup_name: String

signal behavior_activated(behavior: StoredBehavior)

func initialize(behavior_library: BehaviorLibrary):
	self.behavior_library = behavior_library

func _ready():
	behavior_list = %Behaviors
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

#func _on_delete_from_library_button_pressed_confirmed():
	#var behavior = _behavior_library_ui.get_selected()
	#assert(behavior)
	#_behavior_library.delete(behavior.name)
	#_behavior_library_ui.refresh()

func _on_popup_menu_id_pressed(id: int):
	if id == 0:
		behavior_library.delete(popup_name)
		refresh()
