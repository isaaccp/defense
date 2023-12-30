extends Tree

@export var delete_icon: Texture2D
@export var edit_icon: Texture2D

var _root: TreeItem

func _ready():
	# Note: This is currently only used as a list, not actually a tree.
	# TODO: Do we need nested behaviors?
	var tree = self
	_root = tree.create_item()
	tree.hide_root = true

	tree.set_column_expand(0, false)
	tree.set_column_title(1, "Target")
	tree.set_column_title(2, "Condition")
	tree.set_column_title(3, "Action")

func load_behavior(behavior: Behavior) -> void:
	assert(is_inside_tree(), "Needs to be called inside tree")
	for rule in behavior.rules:
		_add_prefilled(rule)

func _add_empty() -> TreeItem:
	var create = self.create_item(_root)
	create.add_button(0, delete_icon, 0, true, "Delete")
	create.set_selectable(0, false)
	create.set_text(1, "[Target]")
	create.set_text(2, "[Condition]")
	create.set_text(3, "[Action]")
	return create
	
func _add_prefilled(rule: Rule) -> TreeItem:
	var create = self.create_item(_root)
	create.add_button(0, delete_icon, 0, true, "Delete")
	create.set_selectable(0, false)
	create.set_text(1, str(rule.target_selection))
	create.set_metadata(1, rule.target_selection.id)
	create.set_text(2, "Always")
	create.set_metadata(2, 0)
	create.set_text(3, str(rule.action))
	create.set_metadata(3, rule.action.id)
	return create
	

func _is_empty(item: TreeItem) -> bool:
	for c in range(columns):
		if item.get_metadata(c) != null:
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

	if offset < 0:
		var new = _add_empty()
		new.move_before(item)
		item = new
	elif offset > 0:
		var new = _add_empty()
		new.move_after(item)
		item = new
	elif _is_empty(item):
		# Add a new blank item for creating new behaviors
		_add_empty()

	item.set_button_disabled(0, 0, false)
	item.set_text(col, data.text)
	item.set_metadata(col, data.id)
	if data.has_placeholders:
		item.add_button(col, edit_icon, 0, false, "Configure")
	elif item.get_button_count(col) > 0:
		item.erase_button(col, 0)

func _on_button_clicked(item, column, button_id, _mouse_button_index):
	if column == 0 and button_id == 0: # delete
		item.free()
	if column != 0 and button_id == 0: # config
		%ConfigPane.setup(item, column)

func _on_config_pane_config_confirmed(item: TreeItem, col, result):
	item.set_text(col, result)
