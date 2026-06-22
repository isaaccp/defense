extends Node

class_name Run

var ui_layer: GameplayUILayer
var run_save_state: RunSaveState
var milestone_manager: MilestoneManager

var level_provider: LevelProvider:
	get:
		return run_save_state.level_provider
	set(value):
		assert(false, "level_provider should not be set")
var gameplay_characters: Array[GameplayCharacter]:
	get:
		return run_save_state.gameplay_characters
	set(value):
		run_save_state.gameplay_characters = value

var state = StateMachine.new(Constants.RunStateMachineName)
var CHARACTER_SELECTION = state.add("character_selection")
var WITHIN_LEVEL = state.add("within_level")
var REWARD_STAGE = state.add("reward_stage")
var RUN_SUMMARY = state.add("run_summary")

# State-dependent variables.
# If in WITHIN_LEVEL, current level being played.
var level: Level
var level_scene: PackedScene
# Saved in WITHIN_LEVEL, to be used during REWARD_STAGE.
var level_xp: int

# A copy of run_save_state when level is entered for first time.
# Allows to reset state.
var run_save_state_snapshot: RunSaveState

signal run_finished
signal level_paused
signal level_resumed
signal save_requested

func _ready():
	state.connect_signals(self)
	# Needs to happen before we change level, otherwise we
	# could end up adding the level state machine.
	ui_layer.state_machine_stack.add_state_machine(state)
	# If we restored from a save game, gameplay_characters should be set,
	# go straight to level.
	if gameplay_characters.size() == 0:
		state.change_state(CHARACTER_SELECTION)
	else:
		if run_save_state.current_phase == RunSaveState.Phase.REWARD:
			state.change_state(REWARD_STAGE)
		else:
			state.change_state(WITHIN_LEVEL)

func _exit_tree():
	ui_layer.state_machine_stack.remove_state_machine(state)

func initialize(run_save_state: RunSaveState, ui_layer: GameplayUILayer, milestone_manager: MilestoneManager):
	self.run_save_state = run_save_state
	self.ui_layer = ui_layer
	self.milestone_manager = milestone_manager
	# Technically only needed during LEVEL state, but easier than connect/disconnect.
	ui_layer.restart_requested.connect(_on_restart_requested)
	ui_layer.reset_requested.connect(_on_reset_requested)
	ui_layer.abandon_run_requested.connect(_on_abandon_run_requested)
	ui_layer.behavior_modified.connect(_on_behavior_modified)
	ui_layer.relic_selected.connect(_on_relic_selected)
	ui_layer.reward_state_changed.connect(func(): save_requested.emit())

func _on_gold_earned(amount: int) -> void:
	run_save_state.gold += amount

func _on_character_selection_entered():
	ui_layer.start_character_selection(level_provider)
	ui_layer.character_selection_screen_selection_ready.connect(_on_character_selection_finished, CONNECT_ONE_SHOT)

func _on_character_selection_finished(character_selections: Array[int]):
	var players = OnlineMatch.get_sorted_players()
	for selection in range(character_selections.size()):
		var idx = character_selections[selection]
		# TODO: Remove the number when we don't allow two of
		# the same character.
		var gameplay_character = level_provider.available_characters[idx].duplicate(true) as GameplayCharacter
		gameplay_character.initialize(
			"%s (%d)" % [gameplay_character.name, selection],
			players[selection % players.size()].peer_id,
			level_provider.behavior
		)
		gameplay_characters.append(gameplay_character)
	state.change_state.call_deferred(WITHIN_LEVEL)

func _on_character_selection_exited():
	ui_layer.end_character_selection()

func _on_behavior_modified(character_idx: int, behavior: StoredBehavior):
	gameplay_characters[character_idx].behavior = behavior
	BehaviorComponent.get_or_die(level.characters.get_child(character_idx)).stored_behavior = behavior

	# TODO: Fix and uncomment for multiplayer.
	# _on_peer_behavior_modified.rpc(character_idx, behavior.serialize())

func _on_within_level_entered(save_snapshot: bool = true):
	if save_snapshot:
		_snapshot_run_save_state()
	level_scene = _pick_fight_level(run_save_state.current_stage)
	if not level_scene:
		# No levels at this difficulty — the run is over.
		state.change_state.call_deferred(RUN_SUMMARY)
		return
	level = level_scene.instantiate()
	level.initialize(gameplay_characters, run_save_state.unlocked_skills)
	level.selected_relics = []
	level.level_failed.connect(_on_level_failed)
	level.level_finished.connect(_on_level_finished)
	level.gold_earned.connect(_on_gold_earned)
	
	level.prepare_started.connect(_on_level_prepare_started)
	level.prepare_exited.connect(_on_level_prepare_exited)
	level.combat_started.connect(_on_level_combat_started)
	level.combat_exited.connect(_on_level_combat_exited)
	level.summary_started.connect(_on_level_summary_started)
	level.enemy_selected.connect(_on_level_enemy_selected)
	
	ui_layer.play_controls_play_pressed.connect(level.play_combat)
	ui_layer.play_controls_pause_pressed.connect(level.pause_combat)
	ui_layer.play_next_selected.connect(level.play_next)
	ui_layer.try_again_selected.connect(level.try_again)
	
	ui_layer.state_machine_stack.add_state_machine(level.state)
	ui_layer.show()
	ui_layer.hud.set_stage(run_save_state.current_stage)
	ui_layer.hud.show()
	# TODO: Add a MultiplayerSpawner here so scenes get spawned.
	%StateParent.add_child(level, true)

func _destroy_current_level():
	_cleanup_level_connections()
	if is_instance_valid(level):
		ui_layer.state_machine_stack.remove_state_machine(level.state)
		level.exit()
	%StateParent.remove_child(level)
	level = null

func _on_level_failed():
	_destroy_current_level()
	# Run _on_within_level_entered but don't save snapshot.
	_on_within_level_entered(false)

func _on_level_finished():
	# Record xp gains here but apply and show them visually in REWARD_STAGE.
	level_xp = level.granted_xp()
	var level_stats = level.get_aggregate_stats()
	if milestone_manager:
		milestone_manager.evaluate_level_end(level_stats)
	# Needs to be recorded here in case it's the last level.
	run_save_state.stats.add_stat(Stat.make(Stat.LevelsBeaten, 1))
	for gc in gameplay_characters:
		run_save_state.stats.add_character_stat(Stat.make(Stat.LevelsBeaten, 1), gc.scene_id)
	run_save_state.stats.add(level_stats)
	run_save_state.current_phase = RunSaveState.Phase.REWARD
	# Call this in the same frame explicitly so we update all the
	# bits of the RunSaveState in the same frame.
	state.change_state(REWARD_STAGE, false)

func _on_within_level_exited():
	_destroy_current_level()
	ui_layer.hud.hide()
	level_scene = null

func _cleanup_level_connections():
	if is_instance_valid(level):
		if level.prepare_started.is_connected(_on_level_prepare_started):
			level.prepare_started.disconnect(_on_level_prepare_started)
		if level.prepare_exited.is_connected(_on_level_prepare_exited):
			level.prepare_exited.disconnect(_on_level_prepare_exited)
		if level.combat_started.is_connected(_on_level_combat_started):
			level.combat_started.disconnect(_on_level_combat_started)
		if level.combat_exited.is_connected(_on_level_combat_exited):
			level.combat_exited.disconnect(_on_level_combat_exited)
		if level.summary_started.is_connected(_on_level_summary_started):
			level.summary_started.disconnect(_on_level_summary_started)
		if level.enemy_selected.is_connected(_on_level_enemy_selected):
			level.enemy_selected.disconnect(_on_level_enemy_selected)
		
		if ui_layer.play_controls_play_pressed.is_connected(level.play_combat):
			ui_layer.play_controls_play_pressed.disconnect(level.play_combat)
		if ui_layer.play_controls_pause_pressed.is_connected(level.pause_combat):
			ui_layer.play_controls_pause_pressed.disconnect(level.pause_combat)
		if ui_layer.play_next_selected.is_connected(level.play_next):
			ui_layer.play_next_selected.disconnect(level.play_next)
		if ui_layer.try_again_selected.is_connected(level.try_again):
			ui_layer.try_again_selected.disconnect(level.try_again)

func _on_relic_selected(relic_name: String, gc: GameplayCharacter):
	run_save_state.relic_library_state.mark_relic_used(relic_name)
	run_save_state.relic_library_state.clear_relic_selection()
	gc.add_relic(relic_name)

func _on_reward_stage_entered():
	# Grant any pending XP from the level we just finished — happens before
	# the reward stage shows so the trainer reward sees up-to-date XP.
	for character in gameplay_characters:
		character.grant_xp(level_xp)
	level_xp = 0
	save_requested.emit()
	var stage_rewards: StageRewards = run_save_state.reward_schedule[run_save_state.current_stage - 1]
	ui_layer.show_map_screen(stage_rewards, run_save_state)
	ui_layer.reward_stage_continue_selected.connect(_on_reward_stage_continue_selected, CONNECT_ONE_SHOT)

func _on_reward_stage_continue_selected():
	run_save_state.reward_path_chosen = -1
	run_save_state.reward_nodes_claimed.clear()
	run_save_state.current_stage += 1
	run_save_state.current_phase = RunSaveState.Phase.FIGHT
	if level_provider.has_levels_at_difficulty(run_save_state.current_stage):
		state.change_state.call_deferred(WITHIN_LEVEL)
	else:
		state.change_state.call_deferred(RUN_SUMMARY)

func _on_reward_stage_exited():
	ui_layer.hide_map_screen()

func _on_run_summary_entered():
	ui_layer.show_run_summary_screen(_run_stats_text())
	ui_layer.run_summary_continue_selected.connect(_on_run_summary_continue_selected, CONNECT_ONE_SHOT)

func _on_run_summary_exited():
	pass

func _on_run_summary_continue_selected():
	var newly_unlocked: Array[MilestoneManager.MilestoneProgressDelta] = []
	if milestone_manager:
		newly_unlocked = milestone_manager.process_unlocks(run_save_state)
	
	ui_layer.show_milestone_summary_screen(newly_unlocked)
	ui_layer.milestone_summary_continue_selected.connect(_on_milestone_summary_continue_selected, CONNECT_ONE_SHOT)

func _on_milestone_summary_continue_selected():
	finish_run.call_deferred()

func finish_run():
	# TODO: Differentiate failure vs success.
	ui_layer.hud.show_main_message("You rolled credits!", 5.0)
	print("Finished the game")
	run_save_state.stats.add_stat(Stat.make(Stat.RunsCompleted, 1))
	for gc in gameplay_characters:
		run_save_state.stats.add_character_stat(Stat.make(Stat.RunsCompleted, 1), gc.scene_id)
	run_finished.emit()

func _on_restart_requested():
	_on_level_failed()

func _snapshot_run_save_state():
	run_save_state_snapshot = run_save_state.clone()

func _restore_run_save_state_snapshot():
	run_save_state = run_save_state_snapshot

func _on_reset_requested():
	_restore_run_save_state_snapshot()
	_on_level_failed()

func _on_abandon_run_requested():
	get_tree().paused = false
	state.change_state.call_deferred(RUN_SUMMARY)

func _run_stats_text() -> String:
	var text = "Run Complete\n"
	text += "Levels Beaten: %d\n" % run_save_state.stats.get_value(Stat.LevelsBeaten)
	text += "Enemies Destroyed: %d\n" % run_save_state.stats.get_value(Stat.EnemiesDestroyed)
	return text

func paused():
	return state.is_state(WITHIN_LEVEL) and level.paused()

# --- Pool picks ---

# Seed is hashed with the stage index so each stage's pick is deterministic
# (and surviving the same stage twice via retry picks the same level).
func _stage_rng(stage: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:fight" % [run_save_state.seed, stage])
	return rng

func _pick_fight_level(stage: int) -> PackedScene:
	var pool := level_provider.levels_at_difficulty(stage)
	if pool.is_empty():
		return null
	return pool[_stage_rng(stage).randi() % pool.size()]

func _on_level_prepare_started(characters: Node2D, towers: Node2D, selected_relics: Array[RelicDef], victory: Node):
	ui_layer.hud.show_play_controls(false)
	ui_layer.hud.show_level_options(true)
	ui_layer.hud.set_victory_loss(victory)
	ui_layer.hud.set_gameplay_characters(gameplay_characters)
	ui_layer.hud.set_characters(characters)
	ui_layer.hud.set_towers(towers)
	ui_layer.hud.clear_enemy_hud()
	ui_layer.hud.set_level_options(selected_relics)
	ui_layer.hud.start_character_setup(level.complete_character_setup)
	ui_layer.hud.show_main_message("Prepare", 2.0)

func _on_level_prepare_exited():
	ui_layer.hud.show_character_buttons(false)
	ui_layer.hud.show_victory_loss_text(false)

func _on_level_combat_started(ready_to_fight_wait: float):
	ui_layer.hud.show_main_message("Fight!", ready_to_fight_wait)
	ui_layer.hud.show_level_options(false)
	ui_layer.hud.show_play_controls()

func _on_level_combat_exited():
	ui_layer.hud.show_play_controls(false)

func _on_level_summary_started(win: bool, characters: Node2D, xp_text: String):
	ui_layer.hud.show_victory_loss_text(true)
	ui_layer.hud.show_victory_loss(false)
	ui_layer.hide_log_viewer()
	ui_layer.show_level_end(win, characters, xp_text)

func _on_level_enemy_selected(enemy: Enemy):
	ui_layer.hud.set_selected_enemy(enemy)
