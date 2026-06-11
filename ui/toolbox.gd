@tool
class_name Toolbox extends Tree

# Emitted when the user starts dragging a skill from the toolbox. Listeners
# (e.g. the behavior editor) use it to highlight valid drop targets.
signal drag_started(drag_type: BehaviorEditorTypes.SlotType)

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

	_add_section("Target Selection Types", _skills.target_selections, BehaviorEditorTypes.SlotType.TARGET,
		func(n): return SkillManager.make_target_selection_instance(n))
	_add_section("Conditions", _skills.conditions, BehaviorEditorTypes.SlotType.CONDITION,
		func(n): return SkillManager.make_condition_instance(n))
	_add_section("Actions", _skills.actions, BehaviorEditorTypes.SlotType.ACTION,
		func(n): return SkillManager.make_action_instance(n))

func _add_section(title: String, names: Array, column: BehaviorEditorTypes.SlotType, factory: Callable):
	var matching: Array = []
	for n in names:
		if _matches(n):
			matching.append(n)
	if matching.is_empty():
		return
	var header = create_item(_root)
	header.set_text(0, title)
	header.set_selectable(0, false)
	header.set_custom_color(0, Color(0.8, 0.8, 0.8))
	for n in matching:
		var item = create_item(header)
		var skill = factory.call(n)
		item.set_text(0, n)
		item.set_tooltip_text(0, skill.description())
		item.set_metadata(0, metadata(column, n, skill.params))
		
		# Set custom colors for items based on column type
		var profile = SkillStyles.profile_for_slot(column)
		item.set_custom_color(0, profile.color_theme)

func metadata(column: BehaviorEditorTypes.SlotType, name: StringName, params: SkillParams) -> Dictionary:
	return {"column": column, "name": name, "params": params}

func _get_drag_data(at_position: Vector2):
	var item = get_item_at_position(at_position)
	if not item or item.get_parent() == _root: # header
		return null

	var metadata = item.get_metadata(0)
	var drag_type: BehaviorEditorTypes.SlotType = metadata.column
	var text = item.get_text(0)
	if metadata.has("params") and not metadata.params.placeholders.is_empty():
		text = metadata.params.interpolated_text()

	var preview := PanelContainer.new()
	var style := StyleBoxFlat.new()
	
	var profile = SkillStyles.profile_for_slot(drag_type)
	
	# Apply matching shapes and colors
	style.corner_radius_top_left = profile.corner_radius_top_left
	style.corner_radius_top_right = profile.corner_radius_top_right
	style.corner_radius_bottom_right = profile.corner_radius_bottom_right
	style.corner_radius_bottom_left = profile.corner_radius_bottom_left
	
	style.bg_color = profile.bg_color_highlight()
	style.border_color = profile.border_color_highlight()
	style.set_border_width_all(1)
	style.set_content_margin_all(8)
	preview.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color.WHITE)
	preview.add_child(label)

	set_drag_preview(preview)
	drag_started.emit(drag_type)
	return {"type": drag_type, "text": text, "name": metadata.name, "params": metadata.get("params")}
