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

func start(game_mode: GameMode):
	level_provider = game_mode.level_provider
	if game_mode.is_multiplayer():
		assert(level_provider.players == 2)
	ui_layer.show()
	ui_layer.hud.set_peer(multiplayer.get_unique_id())
	ui_layer.character_selection_screen.set_characters(level_provider.players)
	ui_layer.show_screen(ui_layer.character_selection_screen)

func _on_character_selection_screen_selection_ready(character_selections: Array[Enum.CharacterId]):
	ui_layer.hide_screen()
	var players = OnlineMatch.get_sorted_players()
	for selection in range(character_selections.size()):
		var character_id = character_selections[selection]
		# TODO: Remove the number when we don't allow two of
		# the same character.
		var character_name = "%s (%d)" % [Enum.character_id_string(character_id), selection]
		var gameplay_character = GameplayCharacter.make(
			character_id,
			character_name,
			players[selection % players.size()].peer_id,
			level_provider.behavior,
			level_provider.skill_tree_state,
		)
		characters.append(gameplay_character)
	_play_level.call_deferred()

func _play_level(advance: bool = true):
	if advance:
		level_scene = level_provider.next_level()
		# Should only happen if there are no levels.
		if level_scene == null:
			_credits()
			return
	level = level_scene.instantiate() as Level
	level.initialize(characters)
	var victory = Component.get_victory_loss_condition_component_or_die(level)
	victory.level_failed.connect(_on_level_failed)
	victory.level_finished.connect(_on_level_finished)
	ui_layer.hud.set_victory_loss(victory)
	level_parent.add_child(level, true)
	level.freeze(true)
	ui_layer.hud.set_characters(level.characters)
	ui_layer.hud.set_towers(level.towers)
	ui_layer.hud.start_behavior_setup(_on_all_behaviors_ready)
	ui_layer.hud.show_main_message("Prepare", 2.0)
	# Everything is set up, wait until all players are ready.

func _on_level_failed(loss_type: VictoryLossConditionComponent.LossType):
	_on_level_end(false)

func _on_level_finished(victory_type: VictoryLossConditionComponent.VictoryType):
	_on_level_end(true)

func _on_level_end(success: bool):
	ui_layer.hud.show_victory_loss_text(true)
	# TODO: Maybe later have a way to inspect level, e.g. see
	# health of enemies, inspect logs, etc before moving on.
	if success:
		await ui_layer.hud.show_main_message("Victory!", level_end_wait)
	else:
		await ui_layer.hud.show_main_message("Failed!", level_failed_wait)
	ui_layer.hud.show_victory_loss(false)
	level.queue_free()
	if not success:
		_play_level(false)
	else:
		if level_provider.last_level():
			_credits()
			return
		# TODO: Calculate XP, etc, show stats.
		_grant_xp(level)
		ui_layer.show_screen(ui_layer.upgrade_screen)
		ui_layer.upgrade_screen.set_characters(characters)
		ui_layer.hud.start_character_setup(
			"Acquire Skills",
			ui_layer.upgrade_screen.on_acquired_skills_pressed,
			_on_upgrade_done)

func _on_upgrade_done():
	_play_level(true)

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

func _on_all_behaviors_ready():
	_start_level()

func _start_level():
	ui_layer.hud.show_character_button(false)
	ui_layer.hud.show_victory_loss_text(false)
	ui_layer.hud.show_main_message("Fight!", ready_to_fight_wait)
	await get_tree().create_timer(ready_to_fight_wait).timeout
	level.start()
	level_started.emit()
