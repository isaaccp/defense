extends GutTest

const map_screen_scene = preload("res://ui/map_screen.tscn")

class AsyncMockReward extends RewardDef:
	var screen_node: Node
	func _init(node: Node):
		screen_node = node
		display_name = "Mock Title"
		description = "Mock Desc"
	func apply_and_get_outcome(_relic_library: RelicLibrary, _gameplay_characters: Array[GameplayCharacter], ctx: RewardApplyContext) -> String:
		if screen_node:
			await screen_node.get_tree().process_frame
		return "Async Done"

func test_reversibility_and_confirmation():
	var screen := map_screen_scene.instantiate() as MapScreen
	add_child_autoqfree(screen)

	# 1. Setup mock data
	var save_state := SaveState.make_new()
	
	var lp := LevelProvider.new()
	lp.total_stages = 5
	
	var rss := RunSaveState.new()
	rss.gameplay_characters = []
	rss.level_provider = lp
	rss.current_stage = 2
	
	var stage_rewards := StageRewards.new()
	
	var set_a := RewardSet.new()
	set_a.rewards = [AsyncMockReward.new(screen)]
	
	var set_b := RewardSet.new()
	set_b.rewards = [AsyncMockReward.new(screen)]
	
	stage_rewards.sets = [set_a, set_b]
	
	# 2. Show the screen
	screen.custom_minimum_size = Vector2(1024, 600)
	screen._on_show({
		"save_state": save_state,
		"run_save_state": rss,
		"stage_rewards": stage_rewards
	})
	
	# Wait 3 frames for UI children to build and MapGraph to layout.
	await wait_process_frames(3)
	
	var graph = screen.map_graph
	
	# 3. Assert Title and Initial State
	var title_lbl: Label = screen.get_node("%Title") as Label
	assert_string_contains(title_lbl.text, "Stage 2 of 5")
	
	assert_eq(graph.get_chosen_path_idx(), -1)
	assert_false(screen._has_claimed_any_reward)
	
	assert_eq(graph._paths.size(), 2)
	
	# Verify node states
	var node_a = graph._paths[0][0]
	var node_b = graph._paths[1][0]
	assert_eq(node_a.state, RewardNode.State.PRECHOICE)
	assert_eq(node_b.state, RewardNode.State.PRECHOICE)
	
	# 4. Choose Set A (index 0) by clicking its path area
	graph.lock_path(0)
	
	assert_eq(graph.get_chosen_path_idx(), 0)
	
	node_a.clicked.emit(node_a)
	
	# Wait for async apply to finish since _on_node_clicked will trigger the claim
	await wait_process_frames(2)
	
	assert_eq(node_a.state, RewardNode.State.DONE)
	assert_eq(node_b.state, RewardNode.State.GREYED)
	
	assert_true(screen._has_claimed_any_reward)
	
	# 5. Check reversibility after claim (should NOT allow changing choice)
	node_b.clicked.emit(node_b)
	# MapScreen's node click logic doesn't allow changing path
	assert_eq(graph.get_chosen_path_idx(), 0)
	
	# 6. Test confirmation dialog for unclaimed rewards
	watch_signals(screen)
	screen._on_continue_pressed()
	
	# Because we claimed the only reward in path 1, it should just continue
	assert_eq(get_signal_emit_count(screen, "continue_pressed"), 1)
	
	# 7. Now let's test the unclaimed rewards confirmation dialog.
	var set_with_two := RewardSet.new()
	set_with_two.rewards = [AsyncMockReward.new(screen), AsyncMockReward.new(screen)]
	
	stage_rewards.sets = [set_with_two]
	screen._on_show({
		"save_state": save_state,
		"run_save_state": rss,
		"stage_rewards": stage_rewards
	})
	
	await wait_process_frames(1)
	
	var new_graph = screen.map_graph
	var new_node_a = new_graph._paths[0][0]
	var new_node_b = new_graph._paths[0][1]
	
	new_graph.lock_path(0)
	
	# Click first node
	new_node_a.clicked.emit(new_node_a)
	assert_eq(new_graph.get_chosen_path_idx(), 0)
	
	await wait_process_frames(2)
	
	assert_eq(new_node_a.state, RewardNode.State.DONE)
	assert_eq(new_node_b.state, RewardNode.State.PENDING)
	
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
		assert_eq(confirm_dialog.dialog_text, "You are leaving rewards behind — proceed to battle?")
		assert_eq(confirm_dialog.get_ok_button().text, "Proceed")
		# Confirm the dialog
		confirm_dialog.confirmed.emit()
		await wait_process_frames(1)
		# Now continue_pressed should be emitted
		assert_eq(get_signal_emit_count(screen, "continue_pressed"), initial_emits + 1)
