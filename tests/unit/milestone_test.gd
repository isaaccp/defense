extends GutTest

func test_init_populates_defs_from_library():
	var save_state = SaveState.new()
	var library = MilestoneLibrary.new()
	
	var def1 = MilestoneDef.new()
	def1.id = &"test_1"
	
	var def2 = MilestoneDef.new()
	def2.id = &"test_2"
	
	var arr: Array[MilestoneDef] = []
	arr.append(def1)
	arr.append(def2)
	library.milestones = arr
	
	var manager = MilestoneManager.new(save_state, library)
	
	assert_eq(manager.defs.size(), 2)
	assert_eq(manager.defs[0].id, &"test_1")
	assert_eq(manager.defs[1].id, &"test_2")

func test_init_with_empty_library():
	var save_state = SaveState.new()
	var manager = MilestoneManager.new(save_state, null)
	assert_eq(manager.defs.size(), 0)

func test_process_unlocks_promotes_progress_to_unlocked():
	var save_state = SaveState.new()
	var library = MilestoneLibrary.new()
	var def1 = MilestoneDef.new()
	def1.id = &"test_1"
	def1.required_count = 5
	library.milestones.append(def1)
	
	var manager = MilestoneManager.new(save_state, library)
	var run_save_state = RunSaveState.new()
	
	# Start with progress below required count
	save_state.milestone_progress[&"test_1"] = 4
	var unlocked = manager.process_unlocks(run_save_state)
	assert_eq(unlocked.size(), 1)
	assert_eq(unlocked[0].def.id, &"test_1")
	assert_eq(unlocked[0].previous, 0)
	assert_eq(unlocked[0].current, 4)
	assert_false(unlocked[0].unlocked)
	assert_false(unlocked[0].was_unlocked)
	assert_false(save_state.unlocked_milestones.get(&"test_1", false))
	
	# Simulate new run where we reach required count
	run_save_state.starting_milestone_progress[&"test_1"] = 4
	save_state.milestone_progress[&"test_1"] = 5
	unlocked = manager.process_unlocks(run_save_state)
	assert_eq(unlocked.size(), 1)
	assert_eq(unlocked[0].def.id, &"test_1")
	assert_eq(unlocked[0].previous, 4)
	assert_eq(unlocked[0].current, 5)
	assert_true(unlocked[0].unlocked)
	assert_false(unlocked[0].was_unlocked)
	assert_true(save_state.unlocked_milestones.get(&"test_1", false))
	
	# Subsequent calls in same run still return the same delta, unless starting progress is updated
	run_save_state.starting_milestone_progress[&"test_1"] = 5
	run_save_state.unlocked_milestones[&"test_1"] = true # Now it was unlocked
	unlocked = manager.process_unlocks(run_save_state)
	assert_eq(unlocked.size(), 1)
	assert_eq(unlocked[0].current, 5)
	assert_eq(unlocked[0].previous, 5)
	assert_true(unlocked[0].was_unlocked)



