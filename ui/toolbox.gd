@tool
class_name Toolbox extends Tree

# Emitted when the user starts dragging a skill from the toolbox. Listeners
# (e.g. the behavior editor) use it to highlight valid drop targets.
signal drag_started(drag_type: int)

var _root: TreeItem
var _skills: SkillTreeState
var _filter: String = ""

func _init_root():
	_root = create_item()
	hide_root = true

func _clear_tree():
	if not _root:
		return
	for c in _root.get_children():
		_root.remove_child(c)

func initialize(skills: SkillTreeState):
	_skills = skills
	_filter = ""
	_rebuild()

# Case-insensitive substring filter on skill names. Empty string = show all.
func set_filter(text: String) -> void:
	var normalized = text.strip_edges().to_lower()
	if normalized == _filter:
		return
	_filter = normalized
	_rebuild()

func _matches(name: StringName) -> bool:
	if _filter.is_empty():
		return true
	return String(name).to_lower().contains(_filter)

func _rebuild():
	if not _root:
		_init_root()
	_clear_tree()
	if not _skills:
		return

	_add_section("Target Selection Types", _skills.target_selections, 0,
		func(n): return SkillManager.make_target_selection_instance(n))
	_add_section("Conditions", _skills.conditions, 1,
		func(n): return SkillManager.make_condition_instance(n))
	_add_section("Actions", _skills.actions, 2,
		func(n): return SkillManager.make_action_instance(n))

func _add_section(title: String, names: Array, column: int, factory: Callable):
	var matching: Array = []
	for n in names:
		if _matches(n):
			matching.append(n)
	if matching.is_empty():
		return
	var header = create_item(_root)
	header.set_text(0, title)
	header.set_selectable(0, false)
	for n in matching:
		var item = create_item(header)
		var skill = factory.call(n)
		item.set_text(0, n)
		item.set_tooltip_text(0, skill.description())
		item.set_metadata(0, metadata(column, n, skill.params))

func metadata(column: int, name: StringName, params: SkillParams) -> Dictionary:
	return {"column": column, "name": name, "params": params}

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

	drag_started.emit(metadata.column)
	return {"type": metadata.column, "text": preview.text, "name": metadata.name, "params": metadata.get("params")}
