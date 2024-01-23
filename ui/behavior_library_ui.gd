@tool
extends Control

class_name BehaviorLibraryUI

@export var delete_icon: Texture2D
@export var not_available_color: Color

# Initialized from outside.
var behavior_library: BehaviorLibrary
var behavior_editor: BehaviorEditor
var acquired_skills: SkillTreeState

# Internal.
@onready var save_to_library_dialog: AcceptDialog = %SaveBehaviorNameDialog
@onready var behavior_name_line_edit: LineEdit = %BehaviorNameLineEdit
var behavior_list: Tree
var root: TreeItem
var item_by_name: Dictionary


enum Column {
	BUTTONS = 0,
	NAME = 1,
}

enum ButtonIdx {
	DELETE = 0,
}

signal behavior_activated(behavior: StoredBehavior)

func initialize(behavior_library: BehaviorLibrary, acquired_skills: SkillTreeState, behavior_editor: BehaviorEditor):
	self.behavior_library = behavior_library
	self.behavior_editor = behavior_editor
	self.acquired_skills = acquired_skills

func _ready():
	behavior_list = %Behaviors
	root = behavior_list.create_item()
	behavior_list.set_column_expand(Column.BUTTONS, false)
	save_to_library_dialog.register_text_enter(behavior_name_line_edit)
	item_by_name = {}
	if not behavior_library:
		return
	for behavior in behavior_library.behaviors:
		add_item(behavior)

func add_item(behavior: StoredBehavior):
	# TODO: Implement filtering using the LineEdit if at some point
	# we think the built-in search is not good enough.
	var tree_item = behavior_list.create_item(root)
	item_by_name[behavior.name] = tree_item
	update_metadata(behavior)

func update_metadata(behavior: StoredBehavior):
	var tree_item = item_by_name[behavior.name] as TreeItem
	var required_skills = behavior.required_skills()
	var available = acquired_skills.all_available_by_name(required_skills)
	if tree_item.get_button_count(Column.BUTTONS) == 0:
		tree_item.add_button(Column.BUTTONS, delete_icon, ButtonIdx.DELETE, false, "Delete")
	tree_item.set_text(Column.NAME, behavior.name)
	tree_item.set_metadata(Column.NAME, {"available": available})
	tree_item.set_custom_color(Column.NAME, Color.WHITE if available else not_available_color)
	tree_item.set_tooltip_text(Column.NAME, "All skills acquired" if available else "Missing skills")
	tree_item.visible = (not %OnlyAvailableCheckButton.pressed) or available

func get_selected() -> StoredBehavior:
	var tree_item = behavior_list.get_selected()
	if not tree_item:
		return null
	else:
		return behavior_library.get_by_name(tree_item.get_text(Column.NAME))

func _on_behaviors_item_activated():
	behavior_activated.emit(get_selected())

func _on_behaviors_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int):
	if mouse_button_index != 1:
		return
	if column != Column.BUTTONS:
		return
	match id:
		ButtonIdx.DELETE:
			behavior_library.delete(item.get_text(Column.NAME))
			item.free()

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
		update_metadata(behavior)
	else:
		behavior_library.add(behavior)
		add_item(behavior)

func _on_behavior_activated(behavior: StoredBehavior):
	behavior_editor.load_behavior(behavior)

func _on_only_available_check_button_toggled(toggled_on: bool):
	for tree_item in root.get_children():
		var metadata = tree_item.get_metadata(Column.NAME)
		tree_item.visible = (not toggled_on) or metadata.available
