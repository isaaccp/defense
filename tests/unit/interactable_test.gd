extends GutTest

func test_interactable_meets_requirements_defaults_to_true():
	var interactable = autofree(Interactable.new())
	assert_true(interactable.meets_requirements({}))

func test_chest_meets_requirements_with_missing_milestone():
	var chest = autofree(Chest.new())
	# The default milestone is "gold_chests_unlock", which is not in the dict.
	var unlocked_milestones: Dictionary[StringName, bool] = {}
	assert_false(chest.meets_requirements(unlocked_milestones))

func test_chest_meets_requirements_with_present_milestone():
	var chest = autofree(Chest.new())
	var unlocked_milestones: Dictionary[StringName, bool] = {
		&"gold_chests_unlock": true
	}
	assert_true(chest.meets_requirements(unlocked_milestones))

func test_chest_meets_requirements_with_custom_milestone():
	var chest = autofree(Chest.new())
	chest.required_milestone = &"custom_milestone"
	var unlocked_milestones: Dictionary[StringName, bool] = {
		&"custom_milestone": true
	}
	assert_true(chest.meets_requirements(unlocked_milestones))
	unlocked_milestones[&"custom_milestone"] = false
	assert_false(chest.meets_requirements(unlocked_milestones))
