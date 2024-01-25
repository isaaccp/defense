@tool
extends Tree

class_name BehaviorEditorView

@export var delete_icon: Texture2D
@export var edit_icon: Texture2D
@export var drag_icon: Texture2D

const always = preload("res://skill_tree/conditions/always.tres")

var root: TreeItem

var acquired_skills: SkillTreeState

# First loaded behavior, so it can be restored through revert.
var original_behavior: StoredBehavior

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

signal can_save_to_behavior_updated(can_save: bool)
signal can_save_to_behavior_library_updated(can_save: bool)

func initialize(acquired_skills: SkillTreeState):
	self.acquired_skills = acquired_skills

	# Note: This is currently only used as a list, not actually a tree.
	# TODO: Do we need nested behaviors?
	root = create_item()
	hide_root = true

	set_column_expand(Column.BUTTONS, false)
	set_column_title(Column.TARGET, "Target")
	set_column_title(Column.CONDITION, "Condition")
	set_column_title(Column.ACTION, "Action")

func load_behavior(behavior: StoredBehavior) -> void:
	for c in root.get_children():
		root.remove_child(c)
	if behavior:
		var restored_behavior = SkillManager.restore_behavior(behavior)
		for rule in restored_behavior.rules:
			_add_row(rule)
	_add_row()
	_check_can_save()

func _add_row(rule: Rule = null) -> TreeItem:
	var row = create_item(root)
	row.add_button(Column.BUTTONS, drag_icon, ButtonIdx.MOVE, rule == null, "Drag")
	row.add_button(Column.BUTTONS, delete_icon, ButtonIdx.DELETE, rule == null, "Delete")
	row.set_selectable(Column.BUTTONS, false)
	if rule:
		_add_skill(row, Column.TARGET, rule.target_selection)
		_add_skill(row, Column.CONDITION, rule.condition)
		_add_skill(row, Column.ACTION, rule.action)
	else:
		_set_column(row, Column.TARGET, "[Target]", _metadata(TargetSelectionDef.NoTarget))
		_add_skill(row, Column.CONDITION, always)
		_set_column(row, Column.ACTION, "[Action]", _metadata(ActionDef.NoAction))
	return row

func _add_skill(row: TreeItem, column: int, skill: ParamSkill):
	row.set_text(column, str(skill))
	row.set_tooltip_text(column, skill.description())
	row.set_metadata(column, _metadata(skill.skill_name, skill.params))
	_add_button_if_params(row, column, skill.params)
	var acquired = acquired_skills.all_available_by_name(skill.required_skills())
	if not acquired:
		row.set_tooltip_text(column, "Missing skill. Change or delete to be able to use this behavior.")
		row.set_custom_bg_color(column, Color.RED, true)
	else:
		row.clear_custom_bg_color(column)

func _add_button_if_params(row: TreeItem, column: int, params: SkillParams):
	if params and params.placeholders.size() > 0:
		if row.get_button_count(column) == 0:
			row.add_button(column, edit_icon, 0, false, "Configure")
	else:
		if row.get_button_count(column) > 0:
			row.erase_button(column, 0)

func _set_column(row: TreeItem, idx: int, text: String, meta: Dictionary):
	row.set_text(idx, text)
	row.set_metadata(idx, meta)

func _column_empty(column: int, meta):
	match column:
		Column.TARGET:
			return meta == null or meta.name == TargetSelectionDef.NoTarget
		Column.CONDITION:
			# I think the last option should never happen.
			return meta == null or meta.name == always.skill_name or meta.name == ConditionDef.NoCondition
		Column.ACTION:
			return meta == null or meta.name == ActionDef.NoAction
	assert(false, "Unexpected call")
	return false

func _column_valid(column: int, meta):
	match column:
		Column.TARGET:
			return meta != null and meta.name != TargetSelectionDef.NoTarget
		Column.CONDITION:
			return meta != null and meta.name != ConditionDef.NoCondition
		Column.ACTION:
			return meta != null and meta.name != ActionDef.NoAction
	assert(false, "Unexpected call")
	return false

func _column_acquired(_column: int, meta: Dictionary):
	if not meta:
		return false
	var skill = _skill_from_meta(meta)
	return acquired_skills.all_available_by_name(skill.required_skills())

func _is_empty(item: TreeItem) -> bool:
	for c in range(Column.BUTTONS+1, columns): # Skip buttons
		var meta = item.get_metadata(c)
		if not _column_empty(c, meta):
			return false
	return true

# True if all fields are set.
func _is_valid(item: TreeItem) -> bool:
	for c in range(Column.BUTTONS+1, columns): # Skip buttons
		var meta = item.get_metadata(c)
		if not _column_valid(c, meta):
			return false
	return true

func _is_acquired(item: TreeItem) -> bool:
	for c in range(Column.BUTTONS+1, columns): # Skip buttons
		var meta = item.get_metadata(c)
		if not _column_acquired(c, meta):
			return false
	return true

func _metadata(name: StringName, params: SkillParams = null) -> Dictionary:
	return {"name": name, "params": params}

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

func _skill_from_meta(meta) -> ParamSkill:
	var skill = SkillManager.lookup_skill(meta.name)
	var skill_type = skill.skill_type
	match skill_type:
		Skill.SkillType.TARGET: return _target_from_meta(meta)
		Skill.SkillType.ACTION: return _action_from_meta(meta)
		Skill.SkillType.CONDITION: return _condition_from_meta(meta)
	assert(false, "Should not reach")
	return null

func _target_from_meta(meta) -> TargetSelectionDef:
	if not meta or meta.name == TargetSelectionDef.NoTarget:
		return null
	var target = SkillManager.make_target_selection_instance(meta.name)
	target.params = meta.params
	return target

func _condition_from_meta(meta) -> ConditionDef:
	if not meta or meta.name == ConditionDef.NoCondition:
		return null
	var condition = SkillManager.make_condition_instance(meta.name)
	condition.params = meta.params
	return condition

func _action_from_meta(meta) -> ActionDef:
	if not meta or meta.name == ActionDef.NoAction:
		return null
	var action = SkillManager.make_action_instance(meta.name)
	action.params = meta.params
	return action

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
			return not target or condition.compatible_with_target(target.type)
		Column.ACTION:
			action = _action_from_meta(data)
			return not target or action.compatible_with_target(target.type)
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

	var skill = _skill_from_meta(data)
	_add_skill(item, col, skill)

	if was_empty and not _is_empty(item):
		# Replace the blank item we just filled in
		_add_row()

	_check_can_save()

func _on_button_clicked(item, column, button_id, _mouse_button_index):
	if column == Column.BUTTONS:
		if button_id == ButtonIdx.DELETE: # delete
			item.free()
		elif button_id == ButtonIdx.MOVE:
			print("TODO: Make clicking on MOVE do something")
	elif column != Column.BUTTONS and button_id == 0: # config
		%ConfigPane.setup(item, column, acquired_skills)

func _on_config_pane_config_confirmed(item: TreeItem, col, result):
	var params = result as SkillParams
	var text = params.interpolated_text()
	item.set_text(col, text)

func _check_can_save():
	var can_save_to_behavior = true
	var can_save_to_behavior_library = true

	for tree_item in root.get_children():
		if _is_empty(tree_item):
			continue
		if not _is_valid(tree_item):
			can_save_to_behavior = false
			can_save_to_behavior_library = false
			break
		if not _is_acquired(tree_item):
			can_save_to_behavior = false

	can_save_to_behavior_updated.emit(can_save_to_behavior)
	can_save_to_behavior_library_updated.emit(can_save_to_behavior_library)

func get_behavior() -> StoredBehavior:
	var behavior = StoredBehavior.new()
	for child in root.get_children():
		if _is_empty(child):
			continue
		if not _is_valid(child):
			return null
		var target = _target_from_meta(child.get_metadata(Column.TARGET))
		var action = _action_from_meta(child.get_metadata(Column.ACTION))
		var condition = _condition_from_meta(child.get_metadata(Column.CONDITION))
		var rule = RuleDef.make(
			StoredParamSkill.from_skill(target),
			StoredParamSkill.from_skill(action),
			StoredParamSkill.from_skill(condition),
		)
		behavior.stored_rules.append(rule)
	return behavior
