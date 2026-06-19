extends GutTest

func test_is_unlocked_true_when_no_meta_skill():
	var save_state = SaveState.make_new()
	var character = GameplayCharacter.new()
	character.unlock_meta_skill = null
	
	assert_true(character.is_unlocked(save_state.unlocked_skills), "Should be unlocked since no meta skill is required")

func test_is_unlocked_false_when_meta_skill_not_acquired():
	var save_state = SaveState.make_new()
	var character = GameplayCharacter.new()
	
	var skill = Skill.new()
	skill.skill_name = &"test_skill"
	skill.skill_type = Skill.SkillType.META_SKILL
	character.unlock_meta_skill = skill
	
	assert_false(character.is_unlocked(save_state.unlocked_skills), "Should be locked since required meta skill is not acquired")

func test_is_unlocked_true_when_meta_skill_acquired():
	var save_state = SaveState.make_new()
	var character = GameplayCharacter.new()
	
	var skill = Skill.new()
	skill.skill_name = &"test_skill"
	skill.skill_type = Skill.SkillType.META_SKILL
	character.unlock_meta_skill = skill
	
	save_state.unlocked_skills.mark_available(skill)
	
	assert_true(character.is_unlocked(save_state.unlocked_skills))
