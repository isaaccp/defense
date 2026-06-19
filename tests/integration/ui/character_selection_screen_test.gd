extends GutTest

const character_selection_screen_scene = preload("res://ui/character_selection_screen.tscn")

func test_filters_locked_characters_but_maintains_canonical_index():
	var screen = character_selection_screen_scene.instantiate()
	add_child_autoqfree(screen)
	
	var save_state = SaveState.make_new()
	var locked_skill = Skill.new()
	locked_skill.skill_name = &"test_locked"
	locked_skill.skill_type = Skill.SkillType.META_SKILL

	var unlocked_skill = Skill.new()
	unlocked_skill.skill_name = &"test_unlocked"
	unlocked_skill.skill_type = Skill.SkillType.META_SKILL
	
	var char1 = GameplayCharacter.new()
	char1.name = "Unlocked Default"
	char1.unlock_meta_skill = null
	
	var char2 = GameplayCharacter.new()
	char2.name = "Locked Character"
	char2.unlock_meta_skill = locked_skill
	
	var char3 = GameplayCharacter.new()
	char3.name = "Unlocked Later"
	char3.unlock_meta_skill = unlocked_skill
	save_state.unlocked_skills.mark_available(unlocked_skill)
	
	var available_characters: Array[GameplayCharacter] = [char1, char2, char3]
	
	screen.set_characters(1, available_characters, save_state)
	screen._on_show({}) # Initialize UI
	
	# Simulate adding local player
	screen.add_character(0, "local")
	
	# Verify that the selector only instantiated buttons for char1 and char3
	var selector = screen.characters_container.get_child(0)
	var buttons = selector.options.get_children()
	
	assert_eq(buttons.size(), 2, "Should only show 2 characters")
	
	# Verify that the buttons correctly map back to their canonical indices (0 and 2)
	assert_eq(buttons[0].get_meta("character_idx"), 0)
	assert_eq(buttons[1].get_meta("character_idx"), 2)
