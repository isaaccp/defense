extends GutTest

const gold_chests_skill = preload("res://skill_tree/meta_skills/gold_chests.tres")

func test_interactable_meets_requirements_defaults_to_true():
	var interactable = autofree(Interactable.new())
	var unlocked_skills = SkillTreeState.new()
	assert_true(interactable.meets_requirements(unlocked_skills))

func test_chest_meets_requirements_with_missing_skill():
	var chest = autofree(Chest.new())
	var unlocked_skills = SkillTreeState.new()
	assert_false(chest.meets_requirements(unlocked_skills))

func test_chest_meets_requirements_with_present_skill():
	var chest = autofree(Chest.new())
	var unlocked_skills = SkillTreeState.new()
	unlocked_skills.mark_available(gold_chests_skill)
	assert_true(chest.meets_requirements(unlocked_skills))
