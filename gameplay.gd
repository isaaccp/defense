extends Node2D

class_name Gameplay

@export_group("Required")

@export_group("Internal")
@export var ui_layer: GameplayUILayer
@export var level_parent: Node2D

@export_group("Debug")
@export var level_provider: LevelProvider
@export var characters: Array[GameplayCharacter] = []

var level_scene: PackedScene
var level: Level
var characters_ready = {}

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
		var gameplay_character = GameplayCharacter.make(
			character_selections[selection],
			players[selection % players.size()].peer_id,
			Behavior.new(),
			level_provider.skill_tree_state,
		)
		characters.append(gameplay_character)
	_play_level.call_deferred()

func _play_level(advance: bool = true):
	if advance:
		level_scene = level_provider.next_level()
		if level_scene == null:
			ui_layer.hud.show_main_message("You rolled credits!", 5.0)
			print("Finished the game")
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
	ui_layer.hud.start_behavior_setup()
	ui_layer.hud.show_main_message("Prepare", 2.0)
	ui_layer.hud.all_ready.connect(_on_all_ready, CONNECT_ONE_SHOT)
	# Everything is set up, wait until all players are ready.
	
func _on_level_failed(loss_type: VictoryLossConditionComponent.LossType):
	_on_level_end(false)
	
func _on_level_finished(victory_type: VictoryLossConditionComponent.VictoryType):
	_on_level_end(true)
	
func _on_level_end(success: bool):
	var message: String
	if success:
		message = "Level finished!"
	else:
		message = "Level failed!"
	ui_layer.hud.show_victory_loss_text(true)
	# TODO: Maybe later have a way to inspect level, e.g. see
	# health of enemies, inspect logs, etc before moving on.
	ui_layer.hud.show_main_message(message, 5.0)
	await get_tree().create_timer(5.0).timeout
	ui_layer.hud.show_victory_loss(false)
	level.queue_free()
	if not success:
		_play_level(false)
	else:
		# TODO: Calculate XP, etc, show stats.
		# ui_layer.show_screen(ui_layer.upgrade_screen)
		_play_level(true)

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
	ui_layer.hud.show_character_button(false)
	ui_layer.hud.show_victory_loss_text(false)
	ui_layer.hud.show_main_message("Fight!", 1.0)
	await get_tree().create_timer(1.0).timeout
	level.freeze(false)
