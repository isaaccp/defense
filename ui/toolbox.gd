@tool
class_name Toolbox extends Tree

var _root: TreeItem
var _targets: TreeItem
var _triggers: TreeItem
var _actions: TreeItem

func _init_tree():
	var tree = self
	_root = tree.create_item()
	tree.hide_root = true

	_targets = tree.create_item(_root)
	_targets.set_text(0, "Target Selection Types")
	_targets.set_selectable(0, false)

	_triggers = tree.create_item(_root)
	_triggers.set_text(0, "Conditions")
	_triggers.set_selectable(0, false)

	_actions = tree.create_item(_root)
	_actions.set_text(0, "Actions")
	_actions.set_selectable(0, false)

func _clear_tree():
	for header in [_targets, _triggers, _actions]:
		for c in header.get_children():
			header.remove_child(c)

func load_skills(skills: SkillTreeState):
	var tree = self
	if not _root:
		_init_tree()

	_clear_tree()

	if not skills:
		return

	for target_type in skills.acquired_target_selections:
		var target_item = tree.create_item(_targets)
		var target = SkillManager.make_target_selection_instance(target_type)
		target_item.set_text(0, TargetSelectionDef.target_selection_name(target_type))
		target_item.set_tooltip_text(0, target.full_description())
		target_item.set_metadata(0, metadata(0, target_type, target.params))

	for condition_type in skills.acquired_conditions:
		var condition_item = tree.create_item(_triggers)
		var condition = SkillManager.make_condition_instance(condition_type)
		condition_item.set_text(0, condition.name())
		condition_item.set_tooltip_text(0, condition.full_description())
		condition_item.set_metadata(0, metadata(1, condition_type, condition.params))

	for action_type in skills.acquired_actions:
		var action_item = tree.create_item(_actions)
		var action_def = SkillManager.make_action_instance(action_type)
		var action = SkillManager.make_runnable_action(action_def)
		action_item.set_text(0, ActionDef.action_name(action_type))
		action_item.set_tooltip_text(0, action.full_description())
		action_item.set_metadata(0, metadata(2, action_type, action_def.params))

func metadata(column: int, id: int, params: SkillParams) -> Dictionary:
	return {"column": column, "id": id, "params": params}

func _get_drag_data(at_position: Vector2):
	var item = get_item_at_position(at_position)
	if not item or item.get_parent() == _root: # header
		return null

	var preview = Label.new()
	preview.text = item.get_text(0)
	set_drag_preview(preview)
	var metadata = item.get_metadata(0)
	if metadata.has("params") and not metadata.params.placeholders.is_empty():
		preview.text = metadata.params.interpolated_text()

	return {"type": metadata.column, "text": preview.text, "id": metadata.id, "params": metadata.get("params")}
