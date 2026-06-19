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
	
	var text = ""
	
	if not categorized.newly_unlocked.is_empty():
		text += "--- Newly Unlocked ---\n"
		for delta in categorized.newly_unlocked:
			text += "- %s: %d/%d (+%d) [UNLOCKED!]\n" % [delta.def.name, delta.current, delta.required, delta.current - delta.previous]
		text += "\n"
		
	if not categorized.in_progress.is_empty():
		text += "--- In Progress ---\n"
		for delta in categorized.in_progress:
			text += "- %s: %d/%d (+%d)\n" % [delta.def.name, delta.current, delta.required, delta.current - delta.previous]
		text += "\n"
		
	if not categorized.previously_unlocked.is_empty():
		text += "--- Previously Unlocked ---\n"
		for delta in categorized.previously_unlocked:
			text += "- %s: Completed\n" % [delta.def.name]
		text += "\n"
		
	if not categorized.visible_no_progress.is_empty():
		text += "--- Visible (No Progress) ---\n"
		for delta in categorized.visible_no_progress:
			text += "- %s: %d/%d\n" % [delta.def.name, delta.current, delta.required]
		text += "\n"

	if text.is_empty():
		text = "No milestones to show."
		
	%SummaryTextLabel.text = text

func _on_continue_button_pressed():
	continue_selected.emit()
