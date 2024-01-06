extends Node2D

class_name Gameplay

@export_group("Required")

@export_group("Internal")
@export var ui_layer: GameplayUILayer
@export var level_parent: Node2D

@export_group("Debug")
@export var level_provider: LevelProvider
@export var characters: Array[GameplayCharacter] = []

# Not constants so tests can speed them up.
var ready_to_fight_wait = 1.0
var level_end_wait = 3.0
var level_failed_wait = 1.0

var level_scene: PackedScene
var level: Level
var characters_ready = {}

signal level_started

func _ready():
	# TODO: Encapsulate all the hud business better.
	ui_layer.hud.hide()
	ui_layer.hud.show_play_controls(false)

func start(game_mode: GameMode):
	level_provider = game_mode.level_provider
	if game_mode.is_multiplayer():
		assert(level_provider.players == 2)
	ui_layer.show()
	ui_layer.hud.hide()
	ui_layer.hud.set_peer(multiplayer.get_unique_id())
	ui_layer.character_selection_screen.set_characters(level_provider.players, level_provider.available_characters)
	ui_layer.show_screen(ui_layer.character_selection_screen)

func _on_character_selection_screen_selection_ready(character_selections: Array):
	ui_layer.hide_screen()
	ui_layer.hud.show()
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
		characters.append(gameplay_character)
	play_next_level.call_deferred()

func _initialize_level(advance: bool = true):
	level = null
	if advance:
		level_scene = level_provider.next_level()
		# Should only happen if there are no levels.
		if level_scene == null:
			return
	level = level_scene.instantiate() as Level
	level.initialize(characters)

func play_next_level(advance: bool = true):
	_initialize_level(advance)
	if level == null:
		_credits()
		return
	play_level()

func play_level():
	var victory = Component.get_victory_loss_condition_component_or_die(level)
	victory.level_failed.connect(_on_level_failed)
	victory.level_finished.connect(_on_level_finished)
	ui_layer.hud.set_victory_loss(victory)
	level_parent.add_child(level, true)
	ui_layer.hud.set_characters(level.characters)
	ui_layer.hud.set_towers(level.towers)
	ui_layer.hud.start_character_setup(_on_all_ready)
	ui_layer.hud.show_main_message("Prepare", 2.0)
	# Everything is set up, wait until all players are ready.

func _on_level_failed(loss_type: VictoryLossConditionComponent.LossType):
	_on_level_end(false)

func _on_level_finished(victory_type: VictoryLossConditionComponent.VictoryType):
	_on_level_end(true)

func _on_level_end(success: bool):
	ui_layer.hud.show_victory_loss_text(true)
	ui_layer.hud.show_play_controls(false)
	# TODO: Maybe later have a way to inspect level, e.g. see
	# health of enemies, inspect logs, etc before moving on.
	if success:
		await ui_layer.hud.show_main_message("Victory!", level_end_wait)
	else:
		await ui_layer.hud.show_main_message("Failed!", level_failed_wait)
	ui_layer.hud.show_victory_loss(false)
	# TODO: Set something up that calls _wrapup_level when done.
	ui_layer.hud.show_end_level_confirmation(true, success)
	await ui_layer.hud.end_level_confirmed
	level.queue_free()
	ui_layer.hide_log_viewer()
	# Call play_next_level deferred as otherwise
	# we load the new level before we free the
	# current one.
	if not success:
		play_next_level.call_deferred(false)
	else:
		if level_provider.last_level():
			_credits()
			return
		# TODO: Calculate XP, etc, show stats.
		_grant_xp(level)
		play_next_level.call_deferred(true)

func _grant_xp(level: Level):
	# Level will be freed up on next frame, so this can't do
	# any await, etc.
	for character in characters:
		character.grant_xp(level.xp)

func _credits():
	ui_layer.hud.show_main_message("You rolled credits!", 5.0)
	print("Finished the game")

func _on_behavior_modified(character_idx: int, behavior: Behavior):
	_update_behavior(character_idx, behavior)
	_on_peer_behavior_modified.rpc(character_idx, behavior.serialize())

@rpc("any_peer")
func _on_peer_behavior_modified(character_idx: int, serialized_behavior: PackedByteArray):
	var behavior = Behavior.deserialize(serialized_behavior)
	_update_behavior(character_idx, behavior)

func _update_behavior(character_idx: int, behavior: Behavior):
	characters[character_idx].behavior = behavior

func _on_all_ready():
	_start_level()

func _start_level():
	ui_layer.hud.show_character_buttons(false)
	ui_layer.hud.show_victory_loss_text(false)
	ui_layer.hud.show_main_message("Fight!", ready_to_fight_wait)
	await get_tree().create_timer(ready_to_fight_wait).timeout
	ui_layer.hud.show_play_controls()
	level.start()
	level_started.emit()

func _on_restart_requested():
	# TODO: Maybe find a way to merge with _on_end_level.
	ui_layer.hud.show_play_controls(false)
	level.queue_free()
	play_next_level(false)
