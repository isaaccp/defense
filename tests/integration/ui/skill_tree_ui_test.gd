extends GutTest

const skill_tree_ui_scene = preload("res://ui/skill_tree.tscn")

func test_build_tabs_view_meta_mode():
	var ui = skill_tree_ui_scene.instantiate()
	add_child_autoqfree(ui)
	
	var save_state = SaveState.make_new()
	var provider = LevelProvider.new()
	
	var unlock_skill = Skill.new()
	unlock_skill.skill_name = &"unlock"
	unlock_skill.skill_type = Skill.SkillType.META_SKILL
	
	var char1 = GameplayCharacter.new()
	char1.unlock_meta_skill = null
	var arr1: Array[Skill.TreeType] = [Skill.TreeType.WARRIOR]
	char1.available_skill_trees = arr1
	
	var char2 = GameplayCharacter.new()
	char2.unlock_meta_skill = unlock_skill
	var arr2: Array[Skill.TreeType] = [Skill.TreeType.ROGUE]
	char2.available_skill_trees = arr2
	
	var chars: Array[GameplayCharacter] = [char1, char2]
	provider.available_characters = chars
	
	ui.initialize(SkillTreeUI.Mode.VIEW_META, save_state, provider)
	
	# Wait for ready and build tabs
	await wait_frames(1)
	
	# General and Meta should be visible by default. Warrior should be visible (char1 unlocked).
	# Rogue should NOT be visible (char2 locked).
	var tabs = ui.get_node("%Trees")
	assert_not_null(tabs.get_node_or_null("GENERAL"))
	assert_not_null(tabs.get_node_or_null("META"))
	assert_not_null(tabs.get_node_or_null("WARRIOR"))
	assert_null(tabs.get_node_or_null("ROGUE"))
	
	# Now unlock char2
	save_state.unlocked_skills.mark_available(unlock_skill)
	ui._build_tabs()
	
	assert_not_null(tabs.get_node_or_null("ROGUE"), "Should show Rogue after unlock")

func test_build_tabs_acquire_mode():
	var ui = skill_tree_ui_scene.instantiate()
	add_child_autoqfree(ui)
	
	var save_state = SaveState.make_new()
	
	var char1 = GameplayCharacter.new()
	char1.acquired_skills = SkillTreeState.new()
	var arr1: Array[Skill.TreeType] = [Skill.TreeType.WARRIOR]
	char1.available_skill_trees = arr1
	
	var chars: Array[GameplayCharacter] = [char1]
	save_state.run_save_state = RunSaveState.new()
	save_state.run_save_state.gameplay_characters = chars
	
	ui.initialize(SkillTreeUI.Mode.ACQUIRE, save_state, null, char1)
	
	await wait_frames(1)
	
	var tabs = ui.get_node("%Trees")
	assert_not_null(tabs.get_node_or_null("GENERAL"))
	assert_null(tabs.get_node_or_null("META"), "Meta should not be visible in acquire")
	assert_not_null(tabs.get_node_or_null("WARRIOR"))
	assert_null(tabs.get_node_or_null("ROGUE"))
