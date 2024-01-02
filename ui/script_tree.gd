@tool
extends Tree

class_name ScriptTree

@export var delete_icon: Texture2D
@export var edit_icon: Texture2D

var _root: TreeItem

enum Column {
	DELETE_ICON = 0,
	TARGET = 1,
	CONDITION = 2,
	ACTION = 3,
}

func _ready():
	# Note: This is currently only used as a list, not actually a tree.
	# TODO: Do we need nested behaviors?
	var tree = self
	_root = tree.create_item()
	tree.hide_root = true

	tree.set_column_expand(Column.DELETE_ICON, false)
	tree.set_column_title(Column.TARGET, "Target")
	tree.set_column_title(Column.CONDITION, "Condition")
	tree.set_column_title(Column.ACTION, "Action")

func load_behavior(behavior: Behavior) -> void:
	assert(is_inside_tree(), "Needs to be called inside tree")
	for c in _root.get_children():
		_root.remove_child(c)
	for rule in behavior.rules:
		_add_prefilled(rule)
	_add_empty()

func _add_empty() -> TreeItem:
	var row = self.create_item(_root)
	row.add_button(0, delete_icon, 0, true, "Delete")
	row.set_selectable(0, false)
	row.set_text(Column.TARGET, "[Target]")
	row.set_metadata(Column.TARGET, 0)
	# TODO: Set back to a placeholder when there's a proper condition type.
	row.set_text(Column.CONDITION, "Always")
	row.set_metadata(Column.CONDITION, 0)
	row.set_text(Column.ACTION, "[Action]")
	row.set_metadata(Column.ACTION, 0)
	return row

func _add_prefilled(rule: Rule) -> TreeItem:
	var row = self.create_item(_root)
	row.add_button(Column.DELETE_ICON, delete_icon, 0, false, "Delete")
	row.set_selectable(Column.DELETE_ICON, false)
	row.set_text(Column.TARGET, str(rule.target_selection))
	row.set_metadata(Column.TARGET, rule.target_selection.id)
	row.set_text(Column.CONDITION, "Always")
	row.set_metadata(Column.CONDITION, 0)
	row.set_text(Column.ACTION, str(rule.action))
	row.set_metadata(Column.ACTION, rule.action.id)
	return row

func _is_empty(item: TreeItem) -> bool:
	for c in range(1, columns): # Skip delete
		var meta = item.get_metadata(c)
		# _add_empty leaves the delete button null but 0s the rest,
		# but either is empty enough for our purposes.
		if meta != null && meta != 0:
			return false
	return true

func _can_drop_data(at_position: Vector2, data) -> bool:
	var item = get_item_at_position(at_position)
	if not item:
		return false
	if _is_empty(item):
		set_drop_mode_flags(Tree.DROP_MODE_ON_ITEM)
	else:
		set_drop_mode_flags(Tree.DROP_MODE_INBETWEEN | Tree.DROP_MODE_ON_ITEM)
	var section = get_drop_section_at_position(at_position)
	var col = get_column_at_position(at_position)
	if section == -100:
		# TODO: append?
		return false
	if col == data.type+1:
		return true
	return false

func _drop_data(at_position: Vector2, data):
	var offset = get_drop_section_at_position(at_position)
	var item = get_item_at_position(at_position)
	var col = get_column_at_position(at_position)

	var was_empty: bool
	if offset < 0:
		var new = _add_empty()
		new.move_before(item)
		item = new
	elif offset > 0:
		var new = _add_empty()
		new.move_after(item)
		item = new
	elif _is_empty(item):
		# While "Always" is the only condition,
		# dropping it on a row could leave it "empty".
		# So check again after setting.
		was_empty = true

	item.set_button_disabled(Column.DELETE_ICON, 0, false)
	item.set_text(col, data.text)
	item.set_metadata(col, data.id)
	if data.has_placeholders:
		item.add_button(col, edit_icon, 0, false, "Configure")
	elif item.get_button_count(col) > 0:
		item.erase_button(col, 0)

	if was_empty and not _is_empty(item):
		# Replace the blank item we just filled in
		_add_empty()

func _on_button_clicked(item, column, button_id, _mouse_button_index):
	if column == Column.DELETE_ICON and button_id == 0: # delete
		item.free()
	if column != Column.DELETE_ICON and button_id == 0: # config
		%ConfigPane.setup(item, column)

func _on_config_pane_config_confirmed(item: TreeItem, col, result):
	item.set_text(col, result)

func get_behavior() -> Behavior:
	var behavior = Behavior.new()
	for child in _root.get_children():
		if _is_empty(child):
			continue
		var target = child.get_metadata(Column.TARGET) as TargetSelectionDef.Id
		var action = child.get_metadata(Column.ACTION) as ActionDef.Id
		var rule = Rule.make(TargetSelectionDef.make(target), ActionDef.make(action))
		behavior.rules.append(rule)
	return behavior
