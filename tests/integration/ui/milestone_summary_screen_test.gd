extends GutTest

var milestone_summary_scene = preload("res://ui/milestone_summary_screen.tscn")
var screen: Node

func before_each():
	screen = milestone_summary_scene.instantiate()
	add_child_autoqfree(screen)

func test_categorization_and_visibility():
	var def_newly = MilestoneDef.new()
	def_newly.name = "Newly Unlocked"
	var delta_newly = MilestoneManager.MilestoneProgressDelta.new()
	delta_newly.def = def_newly
	delta_newly.unlocked = true
	delta_newly.was_unlocked = false
	delta_newly.current = 10
	delta_newly.previous = 5
	delta_newly.required = 10

	var def_in_prog = MilestoneDef.new()
	def_in_prog.name = "In Progress"
	var delta_in_prog = MilestoneManager.MilestoneProgressDelta.new()
	delta_in_prog.def = def_in_prog
	delta_in_prog.unlocked = false
	delta_in_prog.was_unlocked = false
	delta_in_prog.current = 5
	delta_in_prog.previous = 2
	delta_in_prog.required = 10

	var def_prev = MilestoneDef.new()
	def_prev.name = "Previously Unlocked"
	var delta_prev = MilestoneManager.MilestoneProgressDelta.new()
	delta_prev.def = def_prev
	delta_prev.unlocked = true
	delta_prev.was_unlocked = true
	delta_prev.current = 10
	delta_prev.previous = 10
	delta_prev.required = 10

	var def_vis_no_prog = MilestoneDef.new()
	def_vis_no_prog.name = "Visible No Progress"
	def_vis_no_prog.visibility = MilestoneDef.Visibility.VISIBLE
	var delta_vis_no_prog = MilestoneManager.MilestoneProgressDelta.new()
	delta_vis_no_prog.def = def_vis_no_prog
	delta_vis_no_prog.unlocked = false
	delta_vis_no_prog.was_unlocked = false
	delta_vis_no_prog.current = 0
	delta_vis_no_prog.previous = 0
	delta_vis_no_prog.required = 10

	var def_secret = MilestoneDef.new()
	def_secret.name = "Secret No Progress"
	def_secret.visibility = MilestoneDef.Visibility.SECRET
	var delta_secret = MilestoneManager.MilestoneProgressDelta.new()
	delta_secret.def = def_secret
	delta_secret.unlocked = false
	delta_secret.was_unlocked = false
	delta_secret.current = 0
	delta_secret.previous = 0
	delta_secret.required = 10

	var def_hidden_prog = MilestoneDef.new()
	def_hidden_prog.name = "Hidden With Progress"
	def_hidden_prog.visibility = MilestoneDef.Visibility.HIDDEN_UNTIL_PROGRESS
	var delta_hidden_prog = MilestoneManager.MilestoneProgressDelta.new()
	delta_hidden_prog.def = def_hidden_prog
	delta_hidden_prog.unlocked = false
	delta_hidden_prog.was_unlocked = false
	delta_hidden_prog.current = 2
	delta_hidden_prog.previous = 2
	delta_hidden_prog.required = 10
	
	var def_hidden_no_prog = MilestoneDef.new()
	def_hidden_no_prog.name = "Hidden No Progress"
	def_hidden_no_prog.visibility = MilestoneDef.Visibility.HIDDEN_UNTIL_PROGRESS
	var delta_hidden_no_prog = MilestoneManager.MilestoneProgressDelta.new()
	delta_hidden_no_prog.def = def_hidden_no_prog
	delta_hidden_no_prog.unlocked = false
	delta_hidden_no_prog.was_unlocked = false
	delta_hidden_no_prog.current = 0
	delta_hidden_no_prog.previous = 0
	delta_hidden_no_prog.required = 10

	var deltas: Array[MilestoneManager.MilestoneProgressDelta] = []
	deltas.append(delta_newly)
	deltas.append(delta_in_prog)
	deltas.append(delta_prev)
	deltas.append(delta_vis_no_prog)
	deltas.append(delta_secret)
	deltas.append(delta_hidden_prog)
	deltas.append(delta_hidden_no_prog)

	var result = MilestoneSummaryScreen.categorize_milestones(deltas)
	
	# Verify newly_unlocked bucket
	assert_eq(result.newly_unlocked.size(), 1)
	assert_eq(result.newly_unlocked[0].def.name, "Newly Unlocked")
	
	# Verify in_progress bucket (should exclude secret milestone even if it made progress)
	assert_eq(result.in_progress.size(), 1)
	assert_eq(result.in_progress[0].def.name, "In Progress")
	
	# Verify previously_unlocked bucket
	assert_eq(result.previously_unlocked.size(), 1)
	assert_eq(result.previously_unlocked[0].def.name, "Previously Unlocked")
	
	# Verify visible_no_progress bucket (should include visible and hidden_until_progress with progress)
	assert_eq(result.visible_no_progress.size(), 2)
	
	# Check the contents of visible_no_progress
	var vis_names = []
	for d in result.visible_no_progress:
		vis_names.append(d.def.name)
	assert_true("Visible No Progress" in vis_names)
	assert_true("Hidden With Progress" in vis_names)
	
	# Verify that the filtered milestones are entirely absent from all buckets
	for bucket in result.values():
		for d in bucket:
			assert_ne(d.def.name, "Secret No Progress")
			assert_ne(d.def.name, "Hidden No Progress")
