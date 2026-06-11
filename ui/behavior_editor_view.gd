@tool
extends ScrollContainer

class_name BehaviorEditorView

@export var delete_icon: Texture2D
@export var edit_icon: Texture2D
@export var drag_icon: Texture2D


# Toolbox encodes drag-data 'type' as SlotType.

signal can_save_to_behavior_updated(can_save: bool)
signal can_save_to_behavior_library_updated(can_save: bool)

var acquired_skills: SkillTreeState
var conditions_cap: int = 1

# First loaded behavior, so it can be restored through revert.
var original_behavior: StoredBehavior

# Container of RuleWidgets. Set up in _ready.
var _list: VBoxContainer
var dragged_rule: RuleWidget = null
var drag_click_offset_y: float = 0.0

func _ready():
	_ensure_setup()

# initialize / load_behavior can be called before _ready (e.g. F6 standalone
# constructs the scene, calls initialize, then adds to tree). Idempotently
# build the inner list either way.
func _ensure_setup() -> void:
	if _list:
		return
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	add_child(_list)

func initialize(acquired_skills_: SkillTreeState):
	_ensure_setup()
	acquired_skills = acquired_skills_
	conditions_cap = MaxConditions.cap_for(acquired_skills)

func load_behavior(behavior: StoredBehavior) -> void:
	_ensure_setup()
	for c in _list.get_children():
		c.queue_free()
	if behavior:
		var restored = Behavior.restore(behavior)
		for rule in restored.rules:
			_add_rule_widget(rule)
	_add_rule_widget()  # trailing empty placeholder
	_check_can_save()

func get_behavior() -> StoredBehavior:
	var behavior = StoredBehavior.new()
	for c in _list.get_children():
		var rw = c as RuleWidget
		if rw.is_empty():
			continue
		if not rw.is_valid_rule():
			return null
		behavior.stored_rules.append(rw.to_rule_def())
	return behavior

func collapse_all_conditions() -> void:
	for c in _list.get_children():
		(c as RuleWidget).set_conditions_collapsed(true)

func expand_all_conditions() -> void:
	for c in _list.get_children():
		(c as RuleWidget).set_conditions_collapsed(false)

# Called by the surrounding UI when a drag from the toolbox starts. Highlights
# every valid drop target for the given drag type. NOTIFICATION_DRAG_END fires
# globally on every Control when the drag ends, which we use to un-highlight.
func highlight_drop_targets(drag_type: BehaviorEditorTypes.SlotType) -> void:
	for c in _list.get_children():
		(c as RuleWidget).set_highlight_for_drag(drag_type)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_clear_drop_highlights()
		set_rule_dragging(false)

func _clear_drop_highlights() -> void:
	if not _list:
		return
	for c in _list.get_children():
		(c as RuleWidget).clear_highlight()

func set_rule_dragging(active: bool, rule: RuleWidget = null, click_offset_y: float = 0.0) -> void:
	dragged_rule = rule if active else null
	drag_click_offset_y = click_offset_y if active else 0.0
	if not _list:
		return
	for r in _list.get_children():
		if r is RuleWidget:
			r.set_children_mouse_filter_ignore(active)
			r.update_drag_highlight()

func _add_rule_widget(rule: Rule = null) -> RuleWidget:
	var w = RuleWidget.new(self)
	_list.add_child(w)
	w.load_rule(rule)
	return w

func open_config_pane(params: SkillParams, on_confirm: Callable) -> void:
	%ConfigPane.setup(params, acquired_skills, on_confirm)

func notify_changed() -> void:
	_check_can_save()

func _check_can_save() -> void:
	var can_save_to_behavior := true
	var can_save_to_behavior_library := true
	for c in _list.get_children():
		var rw = c as RuleWidget
		if rw.is_empty():
			continue
		if not rw.is_valid_rule():
			can_save_to_behavior = false
			can_save_to_behavior_library = false
			break
		if not rw.is_all_acquired():
			can_save_to_behavior = false
	can_save_to_behavior_updated.emit(can_save_to_behavior)
	can_save_to_behavior_library_updated.emit(can_save_to_behavior_library)

func reorder_rule(dragged_rule: RuleWidget, target_rule: RuleWidget, relative_y: float) -> void:
	if dragged_rule == target_rule:
		return
	var target_idx := target_rule.get_index()
	var dragged_idx := dragged_rule.get_index()
	
	var drop_after: bool = relative_y >= target_rule.size.y / 2.0
	
	var new_idx := target_idx
	if drop_after:
		new_idx += 1
	
	if dragged_idx < new_idx:
		new_idx -= 1
		
	var max_idx := _list.get_child_count() - 2
	new_idx = clamp(new_idx, 0, max_idx)
	
	print("--- REORDER RULE ---")
	print("Dragged Rule: idx=%d, action=%s, size_y=%.1f" % [dragged_idx, str(dragged_rule._action_cell.get_skill()), dragged_rule.size.y])
	print("Target Rule: idx=%d, action=%s, size_y=%.1f" % [target_idx, str(target_rule._action_cell.get_skill()), target_rule.size.y])
	print("relative_y=%.1f vs target_center_y=%.1f (threshold)" % [relative_y, target_rule.size.y / 2.0])
	print("drop_after=%s, final new_idx=%d" % [str(drop_after), new_idx])
	
	_list.move_child(dragged_rule, new_idx)
	notify_changed()

func _can_drop_data(_at_position: Vector2, data) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.has("is_reorder_rule"):
		var dragged = data.get("rule_widget") as RuleWidget
		print("BehaviorEditorView._can_drop_data: dragged_idx=%d (no-op hover)" % [dragged.get_index() if dragged else -1])
		return true
	return false

func _drop_data(_at_position: Vector2, data) -> void:
	if typeof(data) == TYPE_DICTIONARY and data.has("is_reorder_rule"):
		var dragged = data.get("rule_widget") as RuleWidget
		if dragged:
			var max_idx := _list.get_child_count() - 2
			if max_idx >= 0:
				_list.move_child(dragged, max_idx)
				notify_changed()

# ============================================================================
# DragHandle — button that supports drag-to-reorder rules
# ============================================================================
class DragHandle extends Button:
	var rule_widget: PanelContainer

	func _init(rule_widget_: PanelContainer):
		rule_widget = rule_widget_
		mouse_default_cursor_shape = Control.CURSOR_DRAG

	func _get_drag_data(at_position: Vector2) -> Variant:
		var preview := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
		style.border_color = Color(0.4, 0.4, 0.5, 0.9)
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		style.set_content_margin_all(8)
		preview.add_theme_stylebox_override("panel", style)
		
		var label := Label.new()
		var skill_name = ""
		if rule_widget._action_cell.has_skill():
			skill_name = str(rule_widget._action_cell.get_skill())
		elif rule_widget._target_cell.has_skill():
			skill_name = str(rule_widget._target_cell.get_skill())
			
		if skill_name != "":
			label.text = "Move: " + skill_name
		else:
			label.text = "Move Rule"
		preview.add_child(label)
		
		if get_viewport().gui_is_dragging():
			set_drag_preview(preview)
		else:
			preview.queue_free()
		var click_offset_y = at_position.y
		var curr: Control = self
		while curr and curr != rule_widget:
			click_offset_y += curr.position.y
			curr = curr.get_parent() as Control
		print("DragHandle._get_drag_data: rule_idx=%d, click_offset_y=%.1f" % [rule_widget.get_index(), click_offset_y])
		rule_widget.editor.set_rule_dragging(true, rule_widget, click_offset_y)
		return {
			"is_reorder_rule": true,
			"rule_widget": rule_widget
		}

# ============================================================================
# RuleWidget — one rule (header with target/action + indented conditions list)
# ============================================================================

class RuleWidget extends PanelContainer:
	var editor: BehaviorEditorView
	var _drag_button: Button
	var _delete_button: Button
	var _target_cell: SkillCell
	var _action_cell: SkillCell
	var _conditions_vbox: VBoxContainer

	func _init(editor_: BehaviorEditorView):
		editor = editor_
		_drag_button = DragHandle.new(self)
		_drag_button.icon = editor.drag_icon
		_drag_button.tooltip_text = "Drag to reorder"
		_drag_button.disabled = true
		
		_delete_button = Button.new()
		_delete_button.icon = editor.delete_icon
		_delete_button.tooltip_text = "Delete rule"
		_delete_button.disabled = true
		_delete_button.pressed.connect(_on_delete)
		
		_target_cell = SkillCell.new(editor, BehaviorEditorTypes.SlotType.TARGET, self)
		_target_cell.size_flags_horizontal = SIZE_EXPAND_FILL
		
		_action_cell = SkillCell.new(editor, BehaviorEditorTypes.SlotType.ACTION, self)
		_action_cell.size_flags_horizontal = SIZE_EXPAND_FILL
		
		_conditions_vbox = VBoxContainer.new()
		_conditions_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
		_conditions_vbox.add_theme_constant_override("separation", 2)

	func _ready():
		size_flags_horizontal = SIZE_EXPAND_FILL
		_apply_style(false)
		var outer = VBoxContainer.new()
		add_child(outer)
		# --- header ---
		var header = HBoxContainer.new()
		header.size_flags_horizontal = SIZE_EXPAND_FILL
		outer.add_child(header)
		header.add_child(_drag_button)
		header.add_child(_delete_button)
		header.add_child(_target_cell)
		header.add_child(_action_cell)
		# --- conditions (indented) ---
		var indented = HBoxContainer.new()
		indented.size_flags_horizontal = SIZE_EXPAND_FILL
		outer.add_child(indented)
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(40, 0)
		indented.add_child(spacer)
		indented.add_child(_conditions_vbox)
		_refresh_tooltip()

	func load_rule(rule: Rule) -> void:
		if rule == null:
			return
		_target_cell.set_skill(rule.target_selection)
		_action_cell.set_skill(rule.action)
		for cond in rule.effective_conditions():
			_add_condition_row(cond)
		_enable_buttons()

	func _add_condition_row(cond: ConditionDef) -> ConditionRow:
		var row := ConditionRow.new(editor, self)
		_conditions_vbox.add_child(row)
		row.set_condition(cond)
		_refresh_tooltip()
		return row

	# Same "rule summary" tooltip is pushed to the rule body and every cell,
	# so hovering anywhere on the rule (except utility buttons with their
	# own tooltips) reads the rule as one coherent statement.
	func _refresh_tooltip() -> void:
		var summary := rule_summary()
		tooltip_text = summary
		_target_cell.set_rule_tooltip(summary)
		_action_cell.set_rule_tooltip(summary)
		for row in _conditions_vbox.get_children():
			if row is ConditionRow:
				(row as ConditionRow).set_rule_tooltip(summary)

	func rule_summary() -> String:
		var has_t := _target_cell.has_skill()
		var has_a := _action_cell.has_skill()
		if not has_t and not has_a and _condition_count() == 0:
			return ""
		var cond_strs: PackedStringArray = []
		for row in _conditions_vbox.get_children():
			if row is ConditionRow:
				var c := (row as ConditionRow).get_condition()
				if c:
					cond_strs.append(str(c))
		var when_value := " AND ".join(cond_strs) if not cond_strs.is_empty() else "always"
		var lines: PackedStringArray = []
		lines.append("Action: " + (str(_action_cell.get_skill()) if has_a else "(none)"))
		lines.append("Target: " + (str(_target_cell.get_skill()) if has_t else "(none)"))
		lines.append("When: " + when_value)
		return "\n".join(lines)

	func _enable_buttons() -> void:
		_drag_button.disabled = false
		_delete_button.disabled = false
		_apply_style(true)

	func update_drag_highlight() -> void:
		var has_dragged := (editor.dragged_rule != null)
		var is_this_dragged := (editor.dragged_rule == self)
		_apply_style(not is_empty(), is_this_dragged)
		if has_dragged and not is_this_dragged:
			modulate.a = 0.5
		else:
			modulate.a = 1.0

	# Styling: filled rules get a solid panel; the trailing empty placeholder
	# gets a dashed/faint look so it reads as "drop here to start a new rule."
	func _apply_style(filled: bool, being_dragged: bool = false) -> void:
		var style := StyleBoxFlat.new()
		if being_dragged:
			style.bg_color = Color(0.2, 0.6, 1.0, 0.15)
			style.border_color = Color(0.2, 0.6, 1.0, 0.8)
			style.set_border_width_all(2)
		else:
			style.bg_color = Color(1.0, 1.0, 1.0, 0.04 if filled else 0.0)
			style.border_color = Color(1.0, 1.0, 1.0, 0.25 if filled else 0.12)
			style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		style.set_content_margin_all(4)
		add_theme_stylebox_override("panel", style)

	func is_empty() -> bool:
		return not _target_cell.has_skill() \
			and not _action_cell.has_skill() \
			and _condition_count() == 0

	func is_valid_rule() -> bool:
		return _target_cell.has_skill() and _action_cell.has_skill()

	func is_all_acquired() -> bool:
		if not _target_cell.is_acquired():
			return false
		if not _action_cell.is_acquired():
			return false
		for row in _conditions_vbox.get_children():
			if row is ConditionRow and not (row as ConditionRow).is_acquired():
				return false
		return true

	func get_target_def() -> TargetSelectionDef:
		return _target_cell.get_skill() as TargetSelectionDef

	func to_rule_def() -> RuleDef:
		var target = _target_cell.get_skill() as TargetSelectionDef
		var action = _action_cell.get_skill() as ActionDef
		var conditions: Array[StoredParamSkill] = []
		for row in _conditions_vbox.get_children():
			if not (row is ConditionRow):
				continue
			var cr = row as ConditionRow
			if cr.has_condition():
				conditions.append(cr.to_stored_param_skill())
		return RuleDef.make_with_conditions(
			StoredParamSkill.from_skill(target),
			StoredParamSkill.from_skill(action),
			conditions,
		)

	func remove_condition_row(row: Control) -> void:
		# Remove from the tree synchronously so _refresh_tooltip() (and
		# anything else inspecting children) doesn't see the doomed row.
		# queue_free still does the actual destruction next idle.
		_conditions_vbox.remove_child(row)
		row.queue_free()
		_refresh_tooltip()
		editor.notify_changed()

	func set_conditions_collapsed(collapsed: bool) -> void:
		_conditions_vbox.visible = not collapsed

	# Highlight all slots that would accept the current drag type.
	func set_highlight_for_drag(drag_type: BehaviorEditorTypes.SlotType) -> void:
		match drag_type:
			BehaviorEditorTypes.SlotType.TARGET:
				_target_cell.set_highlighted(true)
			BehaviorEditorTypes.SlotType.ACTION:
				_action_cell.set_highlighted(true)
			BehaviorEditorTypes.SlotType.CONDITION:
				# Highlight every cell on this rule (since a condition can
				# drop anywhere on the rule via forwarding), as long as there
				# is room for another condition.
				if _condition_count() < editor.conditions_cap:
					_target_cell.set_highlighted(true)
					_action_cell.set_highlighted(true)

	func clear_highlight() -> void:
		_target_cell.set_highlighted(false)
		_action_cell.set_highlighted(false)

	func _on_delete() -> void:
		queue_free()
		editor.call_deferred("notify_changed")

	# Whether dropping a new target is compatible with the rule's current action
	# and conditions.
	func _target_change_compatible(new_target: TargetSelectionDef) -> bool:
		var action = _action_cell.get_skill() as ActionDef
		if action and not action.compatible_with_target(new_target.type):
			return false
		for row in _conditions_vbox.get_children():
			if not (row is ConditionRow):
				continue
			var cond = (row as ConditionRow).get_condition()
			if cond and not cond.compatible_with_target(new_target.type):
				return false
		return true

	# Notification from a cell that its skill changed.
	func on_cell_changed() -> void:
		# If we just transitioned out of empty, become a real row and add a
		# new trailing placeholder.
		if not is_empty() and _drag_button.disabled:
			_enable_buttons()
			editor._add_rule_widget()
		_refresh_tooltip()
		editor.notify_changed()

	# Accept condition drops anywhere on the rule widget, or rule reordering.
	func _can_drop_data(at_position: Vector2, data) -> bool:
		if typeof(data) != TYPE_DICTIONARY:
			return false
		if data.has("is_reorder_rule"):
			var dragged = data.get("rule_widget") as RuleWidget
			print("RuleWidget._can_drop_data: target_idx=%d, target_action=%s, dragged_idx=%d, dragged_action=%s, at_position.y=%.1f" % [
				get_index(), str(_action_cell.get_skill()),
				dragged.get_index() if dragged else -1,
				str(dragged._action_cell.get_skill()) if dragged else "none",
				at_position.y
			])
			if dragged and dragged != self:
				editor.reorder_rule(dragged, self, at_position.y)
			return dragged != self
		if not data.has("type"):
			return false
		if data.type != BehaviorEditorTypes.SlotType.CONDITION:
			return false
		if _condition_count() >= editor.conditions_cap:
			return false
		var target := get_target_def()
		if target:
			var cond_def := SkillManager.make_condition_instance(data.name)
			if not cond_def.compatible_with_target(target.type):
				return false
		return true

	func _condition_count() -> int:
		var n := 0
		for c in _conditions_vbox.get_children():
			if c is ConditionRow:
				n += 1
		return n

	func _drop_data(at_position: Vector2, data) -> void:
		if typeof(data) == TYPE_DICTIONARY and data.has("is_reorder_rule"):
			var dragged = data.get("rule_widget") as RuleWidget
			if dragged:
				editor.reorder_rule(dragged, self, at_position.y)
			return
		if data.type != BehaviorEditorTypes.SlotType.CONDITION:
			return
		var cond := SkillManager.make_condition_instance(data.name)
		cond.params = data.params
		_add_condition_row(cond.clone())
		on_cell_changed()

	var _original_mouse_filters := {}

	func set_children_mouse_filter_ignore(ignore: bool) -> void:
		if ignore:
			_original_mouse_filters.clear()
			_set_mouse_filter_recursive(self, true)
			# Ensure the RuleWidget itself does NOT ignore mouse events!
			mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			_restore_mouse_filter_recursive(self)

	func _set_mouse_filter_recursive(node: Node, root: bool) -> void:
		if node is Control:
			if not root:
				_original_mouse_filters[node] = node.mouse_filter
				node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for child in node.get_children():
			_set_mouse_filter_recursive(child, false)

	func _restore_mouse_filter_recursive(node: Node) -> void:
		if node is Control:
			if _original_mouse_filters.has(node):
				node.mouse_filter = _original_mouse_filters[node]
		for child in node.get_children():
			_restore_mouse_filter_recursive(child)

# ============================================================================
# ConditionRow — single condition under a rule
# ============================================================================

class ConditionRow extends HBoxContainer:
	var editor: BehaviorEditorView
	var rule_widget: RuleWidget
	var _delete_button: Button
	var _cell: SkillCell

	func _init(editor_: BehaviorEditorView, rule_widget_: RuleWidget):
		editor = editor_
		rule_widget = rule_widget_
		_delete_button = Button.new()
		_delete_button.icon = editor.delete_icon
		_delete_button.tooltip_text = "Delete condition"
		_delete_button.pressed.connect(_on_delete)
		_cell = SkillCell.new(editor, BehaviorEditorTypes.SlotType.CONDITION, rule_widget)
		_cell.size_flags_horizontal = SIZE_EXPAND_FILL

	func _ready():
		size_flags_horizontal = SIZE_EXPAND_FILL
		add_child(_delete_button)
		add_child(_cell)

	func set_condition(cond: ConditionDef) -> void:
		_cell.set_skill(cond)

	func has_condition() -> bool:
		return _cell.has_skill()

	func get_condition() -> ConditionDef:
		return _cell.get_skill() as ConditionDef

	func is_acquired() -> bool:
		return _cell.is_acquired()

	func to_stored_param_skill() -> StoredParamSkill:
		return _cell.to_stored_param_skill()

	func set_rule_tooltip(t: String) -> void:
		_cell.set_rule_tooltip(t)

	func _on_delete() -> void:
		rule_widget.remove_condition_row(self)

# ============================================================================
# SkillCell — a single Target/Condition/Action slot
# ============================================================================

class SkillCell extends PanelContainer:
	var editor: BehaviorEditorView
	var slot_type: BehaviorEditorTypes.SlotType
	var rule_widget: RuleWidget

	var _skill: ParamSkill
	var _label: Label
	var _edit_button: Button

	func _init(editor_: BehaviorEditorView, slot_type_: BehaviorEditorTypes.SlotType, rule_widget_: RuleWidget):
		editor = editor_
		slot_type = slot_type_
		rule_widget = rule_widget_

	func _ready():
		custom_minimum_size = Vector2(120, 0)
		_apply_style(false)
		var hbox = HBoxContainer.new()
		add_child(hbox)
		_label = Label.new()
		_label.size_flags_horizontal = SIZE_EXPAND_FILL
		_label.mouse_filter = MOUSE_FILTER_IGNORE
		hbox.add_child(_label)
		_edit_button = Button.new()
		_edit_button.icon = editor.edit_icon
		_edit_button.tooltip_text = "Configure"
		_edit_button.visible = false
		_edit_button.pressed.connect(_on_edit)
		hbox.add_child(_edit_button)
		_update_display()

	var _highlighted: bool = false

	# Subtle styled background so cells are visible as drop targets, with a
	# stronger border once filled to make occupied cells obvious.
	func _apply_style(filled: bool) -> void:
		var style := StyleBoxFlat.new()
		var profile = SkillStyles.profile_for_slot(slot_type)
		
		# Apply corner radius from profile
		style.corner_radius_top_left = profile.corner_radius_top_left
		style.corner_radius_top_right = profile.corner_radius_top_right
		style.corner_radius_bottom_right = profile.corner_radius_bottom_right
		style.corner_radius_bottom_left = profile.corner_radius_bottom_left
		
		var bg_color: Color
		var border_color: Color
		var border_width := 1
		
		if _highlighted:
			bg_color = profile.bg_color_highlight()
			border_color = profile.border_color_highlight()
			border_width = 2
		elif filled:
			bg_color = profile.bg_color_filled()
			border_color = profile.border_color_filled()
		else:
			bg_color = profile.bg_color_empty()
			border_color = profile.border_color_empty()
			
		style.bg_color = bg_color
		style.border_color = border_color
		style.set_border_width_all(border_width)
		style.set_content_margin_all(6)
		add_theme_stylebox_override("panel", style)
		
		if _label:
			var text_color: Color = profile.text_color_filled() if filled else profile.text_color_empty()
			_label.add_theme_color_override("font_color", text_color)

	func set_highlighted(on: bool) -> void:
		_highlighted = on
		_apply_style(has_skill())

	func set_skill(skill: ParamSkill) -> void:
		_skill = skill
		_update_display()

	func get_skill() -> ParamSkill:
		return _skill

	func has_skill() -> bool:
		return _skill != null

	func is_acquired() -> bool:
		if not _skill:
			return true
		return editor.acquired_skills.all_available_by_name(_skill.required_skills())

	func to_stored_param_skill() -> StoredParamSkill:
		return StoredParamSkill.from_skill(_skill)

	# Tooltip is pushed by the RuleWidget (rule_summary). _update_display
	# doesn't touch it.
	func set_rule_tooltip(t: String) -> void:
		tooltip_text = t

	func _update_display() -> void:
		if not _label:
			return
		if _skill:
			_label.text = str(_skill)
			_edit_button.visible = _skill.params != null and _skill.params.placeholders.size() > 0
			_label.self_modulate = Color.WHITE if is_acquired() else Color(1.0, 0.6, 0.6)
			_apply_style(true)
		else:
			_label.text = _placeholder_text()
			_edit_button.visible = false
			_label.self_modulate = Color.WHITE
			_apply_style(false)

	func _placeholder_text() -> String:
		match slot_type:
			BehaviorEditorTypes.SlotType.TARGET: return "[Target]"
			BehaviorEditorTypes.SlotType.CONDITION: return "[Condition]"
			BehaviorEditorTypes.SlotType.ACTION: return "[Action]"
		return ""

	func _slot_name() -> String:
		match slot_type:
			BehaviorEditorTypes.SlotType.TARGET: return "target"
			BehaviorEditorTypes.SlotType.CONDITION: return "condition"
			BehaviorEditorTypes.SlotType.ACTION: return "action"
		return ""

	func _can_drop_data(at_position: Vector2, data) -> bool:
		if typeof(data) != TYPE_DICTIONARY or not data.has("type"):
			return false
		if data.type == slot_type:
			return _check_compatibility(data)
		# Forward condition drops to the rule widget so the user can drop a
		# condition anywhere on the rule without hunting for empty space.
		if data.type == BehaviorEditorTypes.SlotType.CONDITION:
			return rule_widget._can_drop_data(at_position, data)
		return false

	func _drop_data(at_position: Vector2, data) -> void:
		if typeof(data) != TYPE_DICTIONARY or not data.has("type"):
			return
		if data.type == slot_type:
			var skill = _create_skill_from_data(data)
			if skill:
				set_skill(skill)
				rule_widget.on_cell_changed()
			return
		if data.type == BehaviorEditorTypes.SlotType.CONDITION:
			rule_widget._drop_data(at_position, data)

	func _check_compatibility(data) -> bool:
		match slot_type:
			BehaviorEditorTypes.SlotType.TARGET:
				var new_target = SkillManager.make_target_selection_instance(data.name)
				return rule_widget._target_change_compatible(new_target)
			BehaviorEditorTypes.SlotType.CONDITION:
				var new_cond = SkillManager.make_condition_instance(data.name)
				var target = rule_widget.get_target_def()
				return target == null or new_cond.compatible_with_target(target.type)
			BehaviorEditorTypes.SlotType.ACTION:
				var new_action = SkillManager.make_action_instance(data.name)
				var target = rule_widget.get_target_def()
				return target == null or new_action.compatible_with_target(target.type)
		return false

	func _create_skill_from_data(data):
		match slot_type:
			BehaviorEditorTypes.SlotType.TARGET:
				var t = SkillManager.make_target_selection_instance(data.name)
				t.params = data.params
				return t
			BehaviorEditorTypes.SlotType.CONDITION:
				var c = SkillManager.make_condition_instance(data.name)
				c.params = data.params
				return c
			BehaviorEditorTypes.SlotType.ACTION:
				var a = SkillManager.make_action_instance(data.name)
				a.params = data.params
				return a
		return null

	func _on_edit() -> void:
		editor.open_config_pane(_skill.params, _on_config_confirmed)

	func _on_config_confirmed(params: SkillParams) -> void:
		_skill.params = params
		_update_display()
		rule_widget.on_cell_changed()
