extends Node

class_name Run

var ui_layer: GameplayUILayer
var run_save_state: RunSaveState

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

# TODO: Make this configurale, or move full meta_xp calculation
# to some helper class.
const meta_xp_per_level = 50

# State-dependent variables.
# If in WITHIN_LEVEL, current level being played.
var level: Level
var level_scene: PackedScene
# Saved in WITHIN_LEVEL, to be used during REWARD_STAGE.
var level_xp: int
# The reward chosen for the current REWARD_STAGE (held so retries / UI
# refreshes don't reroll).
var _current_reward: RewardDef

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
		state.change_state(WITHIN_LEVEL)

func _exit_tree():
	ui_layer.state_machine_stack.remove_state_machine(state)

func initialize(run_save_state: RunSaveState, ui_layer: GameplayUILayer):
	self.ui_layer = ui_layer
	self.run_save_state = run_save_state
	# Technically only needed during LEVEL state, but easier than connect/disconnect.
	ui_layer.restart_requested.connect(_on_restart_requested)
	ui_layer.reset_requested.connect(_on_reset_requested)
	ui_layer.abandon_run_requested.connect(_on_abandon_run_requested)
	ui_layer.behavior_modified.connect(_on_behavior_modified)
	ui_layer.relic_selected.connect(_on_relic_selected)

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
	level.initialize(gameplay_characters, ui_layer)
	level.selected_relics = []
	level.level_failed.connect(_on_level_failed)
	level.level_finished.connect(_on_level_finished)
	level.gold_earned.connect(_on_gold_earned)
	# TODO: Add a MultiplayerSpawner here so scenes get spawned.
	%StateParent.add_child(level, true)

func _on_level_failed():
	level.exit()
	%StateParent.remove_child(level)
	# Run _on_within_level_entered but don't save snapshot.
	_on_within_level_entered(false)

func _on_level_finished():
	# Record xp gains here but apply and show them visually in REWARD_STAGE.
	level_xp = level.granted_xp()
	# Needs to be recorded here in case it's the last level.
	run_save_state.stats.add_stat(Stat.make(Stat.LevelsBeaten, 1))
	run_save_state.current_phase = RunSaveState.Phase.REWARD
	# Call this in the same frame explicitly so we update all the
	# bits of the RunSaveState in the same frame.
	state.change_state(REWARD_STAGE, false)

func _on_within_level_exited():
	level.exit()
	%StateParent.remove_child(level)
	level = null
	level_scene = null

func _on_relic_selected(relic_name: String, gc: GameplayCharacter):
	run_save_state.relic_library_state.mark_relic_used(relic_name)
	run_save_state.relic_library_state.clear_relic_selection()
	gc.add_relic(relic_name)

func _on_reward_stage_entered():
	_current_reward = _pick_reward(run_save_state.current_stage)
	var outcome := ""
	if _current_reward:
		outcome = _current_reward.apply(run_save_state)
	# Always grant pending XP regardless of reward type.
	for character in gameplay_characters:
		character.grant_xp(level_xp)
	level_xp = 0
	save_requested.emit()
	var title := _current_reward.display_name if _current_reward else "Brief Respite"
	var description := _current_reward.description if _current_reward else ""
	var body := description
	if outcome:
		body += "\n\n" + outcome if body else outcome
	ui_layer.show_between_levels_screen(title, body)
	ui_layer.between_levels_continue_selected.connect(_on_reward_stage_continue_selected, CONNECT_ONE_SHOT)

func _on_reward_stage_continue_selected():
	run_save_state.current_stage += 1
	run_save_state.current_phase = RunSaveState.Phase.FIGHT
	if level_provider.has_levels_at_difficulty(run_save_state.current_stage):
		state.change_state.call_deferred(WITHIN_LEVEL)
	else:
		state.change_state.call_deferred(RUN_SUMMARY)

func _on_reward_stage_exited():
	_current_reward = null

func _on_run_summary_entered():
	ui_layer.show_run_summary_screen(_meta_xp_text())
	ui_layer.run_summary_continue_selected.connect(_on_run_summary_continue_selected, CONNECT_ONE_SHOT)

func _on_run_summary_exited():
	pass

func _on_run_summary_continue_selected():
	finish_run.call_deferred()

func finish_run():
	# TODO: Differentiate failure vs success.
	ui_layer.hud.show_main_message("You rolled credits!", 5.0)
	print("Finished the game")
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

func _meta_xp_text() -> String:
	var meta_xp_text = ""
	meta_xp_text += "Meta XP\n"
	meta_xp_text += "Levels Beaten: %d * %d\n" % [run_save_state.stats.get_value(Stat.LevelsBeaten), meta_xp_per_level]
	meta_xp_text += "Total: %d" % meta_xp()
	return meta_xp_text

func meta_xp() -> int:
	return run_save_state.stats.get_value(Stat.LevelsBeaten) * 50

func paused():
	return state.is_state(WITHIN_LEVEL) and level.paused()

# --- Pool picks ---

# Seed is hashed with the stage index so each stage's pick is deterministic
# (and surviving the same stage twice via retry picks the same level).
func _stage_rng(stage: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [run_save_state.get_instance_id(), stage])
	return rng

func _pick_fight_level(stage: int) -> PackedScene:
	var pool := level_provider.levels_at_difficulty(stage)
	if pool.is_empty():
		return null
	return pool[_stage_rng(stage).randi() % pool.size()]

func _pick_reward(stage: int) -> RewardDef:
	var pool := level_provider.available_rewards
	if pool.is_empty():
		return null
	# Mix in a salt so the reward pick and the fight pick at the same stage
	# don't covary visibly.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:reward" % [run_save_state.get_instance_id(), stage])
	return pool[rng.randi() % pool.size()]
