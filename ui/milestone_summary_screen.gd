extends Screen

class_name MilestoneSummaryScreen

signal continue_selected

static func categorize_milestones(unlocked_milestones: Array[MilestoneManager.MilestoneProgressDelta]) -> Dictionary:
	var previously_unlocked: Array[MilestoneManager.MilestoneProgressDelta] = []
	var newly_unlocked: Array[MilestoneManager.MilestoneProgressDelta] = []
	var in_progress: Array[MilestoneManager.MilestoneProgressDelta] = []
	var visible_no_progress: Array[MilestoneManager.MilestoneProgressDelta] = []
	
	for delta in unlocked_milestones:
		if delta.was_unlocked:
			previously_unlocked.append(delta)
		elif delta.unlocked:
			newly_unlocked.append(delta)
		elif delta.current > delta.previous and delta.def.visibility != MilestoneDef.Visibility.SECRET:
			in_progress.append(delta)
		elif delta.current == delta.previous and (delta.def.visibility == MilestoneDef.Visibility.VISIBLE or (delta.def.visibility == MilestoneDef.Visibility.HIDDEN_UNTIL_PROGRESS and delta.current > 0)):
			visible_no_progress.append(delta)
			
	return {
		"previously_unlocked": previously_unlocked,
		"newly_unlocked": newly_unlocked,
		"in_progress": in_progress,
		"visible_no_progress": visible_no_progress
	}

func _on_show(info: Dictionary):
	var unlocked_milestones: Array[MilestoneManager.MilestoneProgressDelta] = info.get("unlocked_milestones", [])
	var categorized = MilestoneSummaryScreen.categorize_milestones(unlocked_milestones)
	var container = %SummaryContainer
	
	for child in container.get_children():
		child.queue_free()

	if categorized.newly_unlocked.is_empty() and categorized.in_progress.is_empty() and categorized.previously_unlocked.is_empty() and categorized.visible_no_progress.is_empty():
		var label = Label.new()
		label.text = "No milestones to show."
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(label)
		return

	var vsplit = VBoxContainer.new()
	vsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vsplit.add_theme_constant_override("separation", 8)
	container.add_child(vsplit)
	
	var unlocked_col = VBoxContainer.new()
	unlocked_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unlocked_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	unlocked_col.add_theme_constant_override("separation", 16)
	vsplit.add_child(unlocked_col)
	
	var progress_col = VBoxContainer.new()
	progress_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	progress_col.add_theme_constant_override("separation", 16)
	vsplit.add_child(progress_col)
	
	# Unlocked Section
	var unl_lbl = Label.new()
	unl_lbl.text = "Unlocked"
	unl_lbl.add_theme_font_size_override("font_size", 24)
	unl_lbl.add_theme_color_override("font_color", Color(0.9, 0.75, 0.1, 1.0))
	unlocked_col.add_child(unl_lbl)
	
	var unl_scroll = ScrollContainer.new()
	unl_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unl_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	unl_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	unlocked_col.add_child(unl_scroll)
	
	var unl_flow = HFlowContainer.new()
	unl_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unl_flow.add_theme_constant_override("h_separation", 16)
	unl_flow.add_theme_constant_override("v_separation", 16)
	unl_scroll.add_child(unl_flow)
	
	for delta in categorized.newly_unlocked:
		unl_flow.add_child(_create_milestone_card(delta, Color(0.9, 0.75, 0.1, 1.0)))
	for delta in categorized.previously_unlocked:
		unl_flow.add_child(_create_milestone_card(delta, Color(0.4, 0.4, 0.4, 1.0)))

	# In Progress Section
	var prog_lbl = Label.new()
	prog_lbl.text = "In Progress"
	prog_lbl.add_theme_font_size_override("font_size", 24)
	prog_lbl.add_theme_color_override("font_color", Color(0.3, 0.6, 0.9, 1.0))
	progress_col.add_child(prog_lbl)
	
	var prog_scroll = ScrollContainer.new()
	prog_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prog_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	prog_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	progress_col.add_child(prog_scroll)
	
	var prog_flow = HFlowContainer.new()
	prog_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prog_flow.add_theme_constant_override("h_separation", 16)
	prog_flow.add_theme_constant_override("v_separation", 16)
	prog_scroll.add_child(prog_flow)
	
	for delta in categorized.in_progress:
		prog_flow.add_child(_create_milestone_card(delta, Color(0.3, 0.6, 0.9, 1.0)))
	for delta in categorized.visible_no_progress:
		prog_flow.add_child(_create_milestone_card(delta, Color(0.3, 0.3, 0.3, 1.0)))

func _create_milestone_card(delta: MilestoneManager.MilestoneProgressDelta, theme_color: Color) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(350, 150)
	panel.size_flags_horizontal = 0
	panel.size_flags_vertical = 0
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12, 0.8)
	style.border_color = theme_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	var top_row = HBoxContainer.new()
	vbox.add_child(top_row)
	
	var title_lbl = Label.new()
	title_lbl.text = delta.def.name
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(title_lbl)
	
	var progress_lbl = Label.new()
	var progress_text = "%d / %d" % [delta.current, delta.required]
	if delta.current > delta.previous:
		progress_text += " (+%d)" % [delta.current - delta.previous]
	if delta.unlocked and not delta.was_unlocked:
		progress_text += "  [UNLOCKED!]"
	progress_lbl.text = progress_text
	progress_lbl.add_theme_color_override("font_color", theme_color)
	top_row.add_child(progress_lbl)
	
	if not delta.def.description.is_empty():
		var desc_lbl = Label.new()
		desc_lbl.text = delta.def.description
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1.0))
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(desc_lbl)
	else:
		var spacer = Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(spacer)
		
	var progress_bar = ProgressBar.new()
	progress_bar.max_value = delta.required
	progress_bar.value = delta.current
	progress_bar.custom_minimum_size.y = 12
	progress_bar.show_percentage = false
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.05, 0.05, 0.05, 1.0)
	bg_style.set_corner_radius_all(3)
	var fg_style = StyleBoxFlat.new()
	fg_style.bg_color = theme_color.darkened(0.2)
	fg_style.set_corner_radius_all(3)
	progress_bar.add_theme_stylebox_override("background", bg_style)
	progress_bar.add_theme_stylebox_override("fill", fg_style)
	vbox.add_child(progress_bar)
	
	if not delta.def.reward_skills.is_empty():
		var skill_names = []
		for s in delta.def.reward_skills:
			if s:
				skill_names.append(s.name())
		if not skill_names.is_empty():
			var reward_lbl = Label.new()
			reward_lbl.text = "Rewards: %s" % ", ".join(skill_names)
			reward_lbl.add_theme_font_size_override("font_size", 12)
			reward_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5, 1.0))
			vbox.add_child(reward_lbl)
			
	return panel

func _on_continue_button_pressed():
	continue_selected.emit()

func _ready():
	if get_tree().current_scene == self:
		var deltas: Array[MilestoneManager.MilestoneProgressDelta] = []
		
		# Newly unlocked
		for i in range(3):
			var d1 = MilestoneManager.MilestoneProgressDelta.new()
			d1.def = preload("res://milestones/defs/behavior_library_unlock.tres")
			d1.previous = 0
			d1.current = 1
			d1.required = 1
			d1.unlocked = true
			d1.was_unlocked = false
			deltas.append(d1)
		
		# In progress
		for i in range(5):
			var d2 = MilestoneManager.MilestoneProgressDelta.new()
			d2.def = preload("res://milestones/defs/compound_conditions_unlock.tres")
			d2.previous = 1
			d2.current = 2
			d2.required = 3
			d2.unlocked = false
			d2.was_unlocked = false
			deltas.append(d2)
		
		# Previously unlocked
		for i in range(10):
			var d3 = MilestoneManager.MilestoneProgressDelta.new()
			d3.def = preload("res://milestones/defs/triple_conditions_unlock.tres")
			d3.previous = 10
			d3.current = 10
			d3.required = 10
			d3.unlocked = true
			d3.was_unlocked = true
			deltas.append(d3)
		
		# Visible no progress
		for i in range(4):
			var d4 = MilestoneManager.MilestoneProgressDelta.new()
			d4.def = preload("res://milestones/defs/gold_chests_unlock.tres")
			d4.previous = 0
			d4.current = 0
			d4.required = 5
			d4.unlocked = false
			d4.was_unlocked = false
			deltas.append(d4)

		_on_show({"unlocked_milestones": deltas})
