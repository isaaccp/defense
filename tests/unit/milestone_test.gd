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
