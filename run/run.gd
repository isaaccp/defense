extends Node

class_name Run

var ui_layer: GameplayUILayer
var level_provider: LevelProvider
var gameplay_characters: Array[GameplayCharacter]

const StateMachineName = "run"
var state = StateMachine.new(StateMachineName)
var CHARACTER_SELECTION = state.add("character_selection")
var WITHIN_LEVEL = state.add("within_level")
var BETWEEN_LEVELS = state.add("between_levels")
var RUN_SUMMARY = state.add("run_summary")

# State-dependent variables.
# If in WITHIN_LEVEL, current level being played.
var level: Level
var level_scene: PackedScene
# A copy of characters' state as they were when level started.
# Allows to reset state.
var characters_snapshot: Array[GameplayCharacter]

signal run_finished
signal level_paused
signal level_resumed

func _ready():
	state.connect_signals(self)
	# If we restored from a save game, gameplay_characters should be set,
	# go straight to level.
	if gameplay_characters.size() == 0:
		state.change_state(CHARACTER_SELECTION)
	else:
		state.change_state(WITHIN_LEVEL)

func initialize(run_save_state: RunSaveState, ui_layer: GameplayUILayer):
	self.ui_layer = ui_layer
	gameplay_characters = run_save_state.gameplay_characters
	level_provider = run_save_state.level_provider
	# Technically only needed during LEVEL state, but easier than connect/disconnect.
	ui_layer.restart_requested.connect(_on_restart_requested)
	ui_layer.reset_requested.connect(_on_reset_requested)
	ui_layer.abandon_run_requested.connect(_on_abandon_run_requested)
	ui_layer.behavior_modified.connect(_on_behavior_modified)
	ui_layer.state_machine_stack.add_state_machine(state)

func _on_character_selection_entered():
	ui_layer.start_character_selection(level_provider)
	ui_layer.character_selection_screen_selection_ready.connect(_on_character_selection_finished)

func _on_character_selection_finished(character_selections: Array[Enum.CharacterId]):
	var players = OnlineMatch.get_sorted_players()
	for selection in range(character_selections.size()):
		var idx = character_selections[selection]
		# TODO: Remove the number when we don't allow two of
		# the same character.
		var gameplay_character = level_provider.available_characters[idx].duplicate(true) as GameplayCharacter
		gameplay_character.name = "%s (%d)" % [gameplay_character.name, selection]
		gameplay_character.peer_id = players[selection % players.size()].peer_id
		if level_provider.behavior:
			gameplay_character.behavior = level_provider.behavior
		if level_provider.skill_tree_state:
			gameplay_character.skill_tree_state = level_provider.skill_tree_state
		gameplay_characters.append(gameplay_character)
	state.change_state.call_deferred(WITHIN_LEVEL)

func _on_character_selection_exited():
	ui_layer.end_character_selection()

func _on_behavior_modified(character_idx: int, behavior: StoredBehavior):
	gameplay_characters[character_idx].behavior = behavior
	# TODO: Fix and uncomment for multiplayer.
	# _on_peer_behavior_modified.rpc(character_idx, behavior.serialize())

func _on_within_level_entered():
	_snapshot_characters()
	level_scene = level_provider.load_level()
	level = level_scene.instantiate()
	level.initialize(gameplay_characters, ui_layer)
	level.level_failed.connect(_on_level_failed)
	level.level_finished.connect(_on_level_finished)
	# TODO: Add a MultiplayerSpawner here so scenes get spawned.
	%StateParent.add_child(level, true)

func _on_level_failed():
	%StateParent.remove_child(level)
	level.queue_free()
	_on_within_level_entered()

func _on_level_finished():
	_grant_xp(level)
	if level_provider.is_last_level():
		state.change_state.call_deferred(RUN_SUMMARY)
	else:
		state.change_state.call_deferred(BETWEEN_LEVELS)

func _grant_xp(level: Level):
	for character in gameplay_characters:
		character.grant_xp(level.xp)

func _on_within_level_exited():
	ui_layer.hud.hide()
	%StateParent.remove_child(level)
	level.queue_free()
	level = null
	level_scene = null

func _on_between_levels_entered():
	# TODO: Do some stuff here like show map/whatever.
	# Should only get here if there are more levels.
	assert(level_provider.advance())
	state.change_state.call_deferred(WITHIN_LEVEL)

func _on_between_levels_exited():
	pass

func _on_run_summary_entered():
	# TODO: Implement run summary screen.
	finish_run.call_deferred()
	# var summary = summary_scene.instantiate() as RunSummary
	# summary.initialize(characters, run_victory)
	# StateParent.add_child(summary)
	# summary.done.connect(finish_run)

func _on_run_summary_exited():
	pass

func finish_run():
	# TODO: Differentiate failure vs success.
	ui_layer.state_machine_stack.remove_state_machine(state)
	ui_layer.hud.show_main_message("You rolled credits!", 5.0)
	print("Finished the game")
	run_finished.emit()

func _on_restart_requested():
	_on_level_failed()

func _snapshot_characters():
	characters_snapshot.clear()
	for character in gameplay_characters:
		characters_snapshot.append(character.duplicate(true))

func _restore_characters_snapshot():
	gameplay_characters.clear()
	for character in characters_snapshot:
		gameplay_characters.append(character)

func _on_reset_requested():
	_restore_characters_snapshot()
	_on_level_failed()

func _on_abandon_run_requested():
	# TODO: Set up something so we can show win/loss.
	state.change_state.call_deferred(RUN_SUMMARY)

func paused():
	return state.is_state(WITHIN_LEVEL) and level.paused()

func get_save_state() -> RunSaveState:
	var run_state = RunSaveState.new()
	run_state.gameplay_characters = gameplay_characters
	run_state.level_provider = level_provider
	return run_state
