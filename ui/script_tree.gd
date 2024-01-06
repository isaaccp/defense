@tool
extends Tree
class_name ScriptTree

@export var delete_icon: Texture2D
@export var edit_icon: Texture2D
@export var drag_icon: Texture2D

const always = preload("res://skill_tree/conditions/always.tres")

var _root: TreeItem

enum Column {
	BUTTONS = 0,
	TARGET = 1,
	CONDITION = 2,
	ACTION = 3,
}

enum ButtonIdx {
	MOVE = 0,
	DELETE = 1,
}

func _ready():
	# Note: This is currently only used as a list, not actually a tree.
	# TODO: Do we need nested behaviors?
	var tree = self
	_root = tree.create_item()
	tree.hide_root = true

	tree.set_column_expand(Column.BUTTONS, false)
	tree.set_column_title(Column.TARGET, "Target")
	tree.set_column_title(Column.CONDITION, "Condition")
	tree.set_column_title(Column.ACTION, "Action")

func load_behavior(behavior: Behavior) -> void:
	assert(is_inside_tree(), "Needs to be called inside tree")
	for c in _root.get_children():
		_root.remove_child(c)
	if behavior.rules:
		for rule in behavior.rules:
			_add_row(rule)
	_add_row()

func _add_row(rule: Rule = null) -> TreeItem:
	var row = self.create_item(_root)
	row.add_button(Column.BUTTONS, drag_icon, ButtonIdx.MOVE, rule == null, "Drag")
	row.add_button(Column.BUTTONS, delete_icon, ButtonIdx.DELETE, rule == null, "Delete")
	row.set_selectable(Column.BUTTONS, false)
	if rule:
		_set_column(row, Column.TARGET, str(rule.target_selection), _metadata(rule.target_selection.id, rule.target_selection.params))
		_add_button_if_params(row, Column.TARGET, rule.target_selection.params)
		_set_column(row, Column.CONDITION, str(rule.condition), _metadata(rule.condition.id, rule.condition.params))
		_add_button_if_params(row, Column.CONDITION, rule.condition.params)
		_set_column(row, Column.ACTION, str(rule.action), _metadata(rule.action.id, rule.action.params))
		_add_button_if_params(row, Column.ACTION, rule.action.params)
	else:
		_set_column(row, Column.TARGET, "[Target]", _metadata(0))
		_set_column(row, Column.CONDITION, str(always), _metadata(always.id, always.params))
		_set_column(row, Column.ACTION, "[Action]", _metadata(0))
	return row

func _add_button_if_params(row: TreeItem, column: int, params: SkillParams) -> bool:
	if params and params.placeholders.size() > 0:
		row.add_button(column, edit_icon, 0, false, "Configure")
		return true
	return false

func _set_column(row: TreeItem, idx: int, name: String, meta: Dictionary):
	row.set_text(idx, name)
	match idx:
		Column.TARGET:
			var target = _target_from_meta(meta)
			if target:
				row.set_tooltip_text(idx, target.full_description())
		Column.CONDITION:
			var condition = _condition_from_meta(meta)
			if condition:
				row.set_tooltip_text(idx, condition.full_description())
		Column.ACTION:
			var action_def = _action_from_meta(meta)
			if action_def:
				var action = SkillManager.make_runnable_action(action_def)
				row.set_tooltip_text(idx, action.full_description())
	row.set_metadata(idx, meta)

func _is_empty(item: TreeItem) -> bool:
	for c in range(Column.BUTTONS+1, columns): # Skip buttons
		var meta = item.get_metadata(c)
		# _add_row leaves the button column null but 0s the rest,
		# but either is empty enough for our purposes.
		if c == Column.CONDITION:
			if meta.id != ConditionDef.Id.ALWAYS:
				return false
		else:
			if meta != null and meta.id != 0:
				return false
	return true

func _is_valid(item: TreeItem) -> bool:
	for c in range(Column.BUTTONS+1, columns): # Skip buttons
		var meta = item.get_metadata(c)
		if meta == null or meta.id == 0:
			return false
	return true

func _metadata(id: int, data: Variant = null) -> Dictionary:
	return {"id": id, "data": data}

func _get_drag_data(at_position):
	var item = get_item_at_position(at_position)
	var col = get_column_at_position(at_position)
	var but = get_button_id_at_position(at_position)
	if item == null || col != Column.BUTTONS || but != ButtonIdx.MOVE:
		return null
	if _is_empty(item):
		return null
	return item

func _can_drop_data(at_position: Vector2, data) -> bool:
	var item = get_item_at_position(at_position)
	if not item:
		return false
	if data is TreeItem:
		if _is_empty(item):
			set_drop_mode_flags(Tree.DROP_MODE_DISABLED)
			return false
		else:
			set_drop_mode_flags(Tree.DROP_MODE_INBETWEEN)
	elif _is_empty(item):
		set_drop_mode_flags(Tree.DROP_MODE_ON_ITEM)
	else:
		set_drop_mode_flags(Tree.DROP_MODE_INBETWEEN | Tree.DROP_MODE_ON_ITEM)
	var section = get_drop_section_at_position(at_position)
	var col = get_column_at_position(at_position)
	if section == -100:
		# TODO: append?
		return false
	if data is TreeItem:
		return true
	elif col == data.type+1:
		return _check_compatibility(item, col, data)
	return false

func _target_from_meta(meta) -> TargetSelectionDef:
	if not meta or meta.id == 0:
		return null
	return SkillManager.make_target_selection_instance(meta.id)

func _condition_from_meta(meta) -> ConditionDef:
	if not meta or meta.id == 0:
		return null
	return SkillManager.make_condition_instance(meta.id) if meta else null

func _action_from_meta(meta) -> ActionDef:
	if not meta or meta.id == 0:
		return null
	return SkillManager.make_action_instance(meta.id) if meta else null

func _check_compatibility(item: TreeItem, column: int, data) -> bool:
	if _is_empty(item):
		return true
	var target = _target_from_meta(item.get_metadata(Column.TARGET))
	var condition = _condition_from_meta(item.get_metadata(Column.CONDITION))
	var action = _action_from_meta(item.get_metadata(Column.ACTION))
	match column:
		Column.TARGET:
			target = _target_from_meta(data)
			if action and not action.compatible_with_target(target.type):
				return false
			if condition and not condition.compatible_with_target(target.type):
				return false
			return true
		Column.CONDITION:
			condition = _condition_from_meta(data)
			if target:
				return condition.compatible_with_target(target.type)
			return true
		Column.ACTION:
			action = _action_from_meta(data)
			if target:
				return action.compatible_with_target(target.type)
			return true
	return false

func _drop_data(at_position: Vector2, data):
	var offset = get_drop_section_at_position(at_position)
	var item = get_item_at_position(at_position)
	var col = get_column_at_position(at_position)

	if data is TreeItem:
		if offset < 0:
			data.move_before(item)
		else:
			data.move_after(item)
		return

	var was_empty: bool
	if offset < 0:
		var new = _add_row()
		new.move_before(item)
		item = new
	elif offset > 0:
		var new = _add_row()
		new.move_after(item)
		item = new
	elif _is_empty(item):
		# While "Always" is the only condition,
		# dropping it on a row could leave it "empty".
		# So check again after setting.
		was_empty = true

	item.set_button_disabled(Column.BUTTONS, ButtonIdx.MOVE, false)
	item.set_button_disabled(Column.BUTTONS, ButtonIdx.DELETE, false)
	_set_column(item, col, data.text,  _metadata(data.id, data.params))
	if not _add_button_if_params(item, col, data.params):
		if item.get_button_count(col) > 0:
			item.erase_button(col, 0)

	if was_empty and not _is_empty(item):
		# Replace the blank item we just filled in
		_add_row()

func _on_button_clicked(item, column, button_id, _mouse_button_index):
	if column == Column.BUTTONS:
		if button_id == ButtonIdx.DELETE: # delete
			item.free()
		elif button_id == ButtonIdx.MOVE:
			print("TODO: Make clicking on MOVE do something")
	elif column != Column.BUTTONS and button_id == 0: # config
		%ConfigPane.setup(item, column)

func _on_config_pane_config_confirmed(item: TreeItem, col, result):
	var params = result as SkillParams
	var text = params.interpolated_text()
	item.set_text(col, text)

func get_behavior() -> Behavior:
	var behavior = Behavior.new()
	for child in _root.get_children():
		# TODO: Actually show something to user if there are invalid rows.
		if not _is_valid(child):
			continue
		var target_id = child.get_metadata(Column.TARGET).id as TargetSelectionDef.Id
		var action_id = child.get_metadata(Column.ACTION).id as ActionDef.Id
		var condition_id = child.get_metadata(Column.CONDITION).id as ConditionDef.Id
		var target = SkillManager.make_target_selection_instance(target_id)
		target.params = child.get_metadata(Column.TARGET).data as SkillParams
		var action = SkillManager.make_action_instance(action_id)
		action.params = child.get_metadata(Column.ACTION).data as SkillParams
		var condition = SkillManager.make_condition_instance(condition_id)
		condition.params = child.get_metadata(Column.CONDITION).data as SkillParams
		var rule = Rule.make(
			target,
			action,
			condition
		)
		behavior.rules.append(rule)
	return behavior
