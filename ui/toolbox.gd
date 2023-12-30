extends Tree

class_name Toolbox

var target_types: Array[TargetSelectionDef.Id]
var action_types: Array[ActionDef.Id]

func initialize(target_selection_types_: Array[TargetSelectionDef.Id], action_types_: Array[ActionDef.Id]):
	target_types = target_selection_types_
	action_types = action_types_

func target_metadata(column: int, id: TargetSelectionDef.Id) -> Dictionary:
	return {"column": column, "id": id}

func action_metadata(column: int, id: ActionDef.Id) -> Dictionary:
	return {"column": column, "id": id}

func condition_metadata(column: int) -> Dictionary:
	return {"column": column}
	
func _ready():
	var tree = self
	var root = tree.create_item()
	tree.hide_root = true

	var targets = tree.create_item(root)
	targets.set_text(0, "Target Selection Types")
	targets.set_selectable(0, false)
	for target_type in target_types:
		var target = tree.create_item(targets)
		target.set_text(0, TargetSelectionDef.name(target_type))
		# FIXME: Metadata needs to contain some actual identification
		target.set_metadata(0, target_metadata(0, target_type))

	var triggers = tree.create_item(root)
	triggers.set_text(0, "Trigger Conditions")
	triggers.set_selectable(0, false)
	for n in ["Always"]:
		var trigger = tree.create_item(triggers)
		trigger.set_text(0, n)
		trigger.set_metadata(0, condition_metadata(1))

	var actions = tree.create_item(root)
	actions.set_text(0, "Actions")
	actions.set_selectable(0, false)
	for action_type in action_types:
		var action = tree.create_item(actions)
		action.set_text(0, ActionDef.name(action_type))
		action.set_metadata(0, action_metadata(2, action_type))

func _get_drag_data(at_position: Vector2):
	var item = get_item_at_position(at_position)
	if item.get_child_count() > 0: # header
		return null
	var preview = Label.new()
	preview.text = item.get_text(0)
	set_drag_preview(preview)
	return {"type": item.get_metadata(0).column, "text": preview.text, "id": item, "has_placeholders": preview.text.contains("{")}
