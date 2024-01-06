@tool
class_name Toolbox extends Tree

var _root: TreeItem

func _ready():
	var tree = self
	_root = tree.create_item()
	tree.hide_root = true

func initialize(
		target_types: Array[TargetSelectionDef.Id],
		action_types: Array[ActionDef.Id],
		condition_types: Array[ConditionDef.Id],
):
	var tree = self
	for c in _root.get_children():
		_root.remove_child(c)

	var targets = tree.create_item(_root)
	targets.set_text(0, "Target Selection Types")
	targets.set_selectable(0, false)
	for target_type in target_types:
		var target = tree.create_item(targets)
		target.set_text(0, TargetSelectionDef.target_selection_name(target_type))
		target.set_metadata(0, target_metadata(0, target_type))

	var triggers = tree.create_item(_root)
	triggers.set_text(0, "Conditions")
	triggers.set_selectable(0, false)
	for condition_type in condition_types:
		var trigger = tree.create_item(triggers)
		var condition = SkillManager.make_condition_instance(condition_type)
		trigger.set_text(0, condition.name())
		trigger.set_metadata(0, condition_metadata(1, condition_type, condition.params))

	var actions = tree.create_item(_root)
	actions.set_text(0, "Actions")
	actions.set_selectable(0, false)
	for action_type in action_types:
		var action_item = tree.create_item(actions)
		var action_def = SkillManager.make_action_instance(action_type)
		var action = SkillManager.make_runnable_action(action_def)
		action_item.set_text(0, ActionDef.action_name(action_type))
		action_item.set_tooltip_text(0, action.full_description())
		action_item.set_metadata(0, action_metadata(2, action_type))

func target_metadata(column: int, id: TargetSelectionDef.Id) -> Dictionary:
	return {"column": column, "id": id}

func action_metadata(column: int, id: ActionDef.Id) -> Dictionary:
	return {"column": column, "id": id}

func condition_metadata(column: int, id: ConditionDef.Id, params: SkillParams) -> Dictionary:
	return {"column": column, "id": id, "params": params}

func _get_drag_data(at_position: Vector2):
	var item = get_item_at_position(at_position)
	if item.get_parent() == _root: # header
		return null

	var preview = Label.new()
	preview.text = item.get_text(0)
	set_drag_preview(preview)
	var metadata = item.get_metadata(0)
	if metadata.has("params") and not metadata.params.placeholders.is_empty():
		preview.text = metadata.params.editor_string

	return {"type": metadata.column, "text": preview.text, "id": metadata.id, "params": metadata.get("params")}
