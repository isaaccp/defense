extends GutTest

const reward_choice_screen_scene = preload("res://ui/reward_choice_screen.tscn")

class AsyncMockReward extends RewardDef:
	var screen_node: Node
	func _init(node: Node):
		screen_node = node
	func apply_and_get_outcome(_relic_library: RelicLibrary, _gameplay_characters: Array[GameplayCharacter], ctx: RewardApplyContext) -> String:
		if screen_node:
			await screen_node.get_tree().process_frame
		return "Async Done"

func test_reversibility_and_confirmation():
	var screen := reward_choice_screen_scene.instantiate() as RewardChoiceScreen
	add_child_autoqfree(screen)

	# 1. Setup mock data
	var save_state := SaveState.make_new()
	
	var lp := LevelProvider.new()
	lp.total_stages = 5
	
	var rss := RunSaveState.new()
	rss.gameplay_characters = []
	rss.level_provider = lp
	rss.current_stage = 2
	
	# Let's build StageRewards with two sets, each having one reward.
	var stage_rewards := StageRewards.new()
	
	var set_a := RewardSet.new()
	set_a.rewards = [AsyncMockReward.new(screen)]
	
	var set_b := RewardSet.new()
	set_b.rewards = [AsyncMockReward.new(screen)]
	
	stage_rewards.sets = [set_a, set_b]
	
	# 2. Show the screen
	screen._on_show({
		"save_state": save_state,
		"run_save_state": rss,
		"stage_rewards": stage_rewards
	})
	
	# Wait 1 frame for UI children to build.
	await wait_frames(1)
	
	# 3. Assert Title and Initial State
	var title_lbl: Label = screen.get_node("%Title") as Label
	assert_string_contains(title_lbl.text, "Stage 2 of 5")
	
	assert_eq(screen._chosen_set_idx, -1)
	assert_false(screen._has_claimed_any_reward)
	
	var panels = screen._set_panels
	assert_eq(panels.size(), 2)
	
	# Verify choose buttons are visible
	assert_true(panels[0]._choose_button.visible)
	assert_true(panels[1]._choose_button.visible)
	
	# Verify card states
	assert_eq(panels[0].cards[0].state, RewardChoiceScreen.RewardCard.State.PRECHOICE)
	assert_eq(panels[1].cards[0].state, RewardChoiceScreen.RewardCard.State.PRECHOICE)
	
	# 4. Choose Set A (index 0)
	screen.on_set_chosen(0)
	
	assert_eq(screen._chosen_set_idx, 0)
	assert_false(panels[0]._choose_button.visible)
	assert_true(panels[1]._choose_button.visible)
	assert_eq(panels[0].cards[0].state, RewardChoiceScreen.RewardCard.State.PENDING)
	assert_eq(panels[1].cards[0].state, RewardChoiceScreen.RewardCard.State.PRECHOICE)
	
	# 5. Switch to Set B (index 1) - because we haven't claimed any reward yet
	screen.on_set_chosen(1)
	
	assert_eq(screen._chosen_set_idx, 1)
	assert_true(panels[0]._choose_button.visible)
	assert_false(panels[1]._choose_button.visible)
	assert_eq(panels[0].cards[0].state, RewardChoiceScreen.RewardCard.State.PRECHOICE)
	assert_eq(panels[1].cards[0].state, RewardChoiceScreen.RewardCard.State.PENDING)
	
	# 6. Click Set B's card to lock in
	# Directly simulate clicking the card
	screen.on_reward_card_clicked(panels[1].cards[0])
	
	# Verify that the Continue button is disabled during progress
	assert_true(screen.get_node("%Continue").disabled)
	
	# Wait for the async apply to run.
	await wait_frames(2)
	
	# Verify that the Continue button is enabled again after completion
	assert_false(screen.get_node("%Continue").disabled)
	
	assert_true(screen._has_claimed_any_reward)
	
	# Choice buttons should now be hidden on ALL panels
	assert_false(panels[0]._choose_button.visible)
	assert_false(panels[1]._choose_button.visible)
	
	# Panel 0 (unchosen) should now be greyed out, and its cards greyed
	assert_eq(panels[0].cards[0].state, RewardChoiceScreen.RewardCard.State.GREYED)
	# Panel 1 (chosen) card should be DONE
	assert_eq(panels[1].cards[0].state, RewardChoiceScreen.RewardCard.State.DONE)
	
	# 7. Check reversibility after claim (should NOT allow changing choice)
	screen.on_set_chosen(0)
	assert_eq(screen._chosen_set_idx, 1)
	
	# 8. Test confirmation dialog for unclaimed rewards
	# In this case, since Set B's card is DONE, there are no unclaimed rewards left in Set B.
	watch_signals(screen)
	screen._on_continue_pressed()
	assert_eq(get_signal_emit_count(screen, "continue_pressed"), 1)
	
	# 9. Now let's test the unclaimed rewards confirmation dialog.
	var set_with_two := RewardSet.new()
	set_with_two.rewards = [AsyncMockReward.new(screen), AsyncMockReward.new(screen)]
	
	stage_rewards.sets = [set_with_two]
	screen._on_show({
		"save_state": save_state,
		"run_save_state": rss,
		"stage_rewards": stage_rewards
	})
	
	await wait_frames(1)
	screen.on_set_chosen(0)
	assert_eq(screen._chosen_set_idx, 0)
	
	# Claim the first reward
	screen.on_reward_card_clicked(screen._set_panels[0].cards[0])
	
	# Verify that the Continue button is disabled during progress
	assert_true(screen.get_node("%Continue").disabled)
	
	# Wait for the async apply to run.
	await wait_frames(2)
	
	# Verify that the Continue button is enabled again after completion
	assert_false(screen.get_node("%Continue").disabled)
	
	assert_eq(screen._set_panels[0].cards[0].state, RewardChoiceScreen.RewardCard.State.DONE)
	assert_eq(screen._set_panels[0].cards[1].state, RewardChoiceScreen.RewardCard.State.PENDING)
	
	var initial_emits: int = get_signal_emit_count(screen, "continue_pressed")
	
	# Call continue - it should spawn a confirmation dialog instead of emitting continue_pressed immediately
	screen._on_continue_pressed()
	assert_eq(get_signal_emit_count(screen, "continue_pressed"), initial_emits)
	
	# Find the ConfirmationDialog child
	var confirm_dialog: ConfirmationDialog = null
	for child in screen.get_children():
		if child is ConfirmationDialog:
			confirm_dialog = child
			break
	
	assert_not_null(confirm_dialog)
	if confirm_dialog:
		assert_eq(confirm_dialog.dialog_text, "You are leaving rewards behind — proceed?")
		assert_eq(confirm_dialog.get_ok_button().text, "Proceed")
		# Confirm the dialog
		confirm_dialog.confirmed.emit()
		await wait_frames(1)
		# Now continue_pressed should be emitted
		assert_eq(get_signal_emit_count(screen, "continue_pressed"), initial_emits + 1)
