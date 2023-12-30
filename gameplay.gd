extends Node2D

class_name Gameplay

@export_group("Internal")
@export var ui_layer: GameplayUILayer
@export var level_parent: Node2D

const level_scene = preload("res://levels/level.tscn")

@export_group("Debug")
@export var characters: Array[GameplayCharacter] = []

var level: Level
var characters_ready = {}

func start():
	ui_layer.show()
	ui_layer.hud.set_peer(multiplayer.get_unique_id())
	ui_layer.character_selection_screen.set_characters(2)
	ui_layer.show_screen(ui_layer.character_selection_screen)

func _on_character_selection_screen_selection_ready(character_selections: Array[Enum.CharacterId]):
	ui_layer.hide_screen()
	var players = OnlineMatch.get_sorted_players()
	for selection in range(character_selections.size()):
		var gameplay_character = GameplayCharacter.new()
		gameplay_character.character_id = character_selections[selection]
		gameplay_character.peer_id = players[selection % players.size()].peer_id
		characters.append(gameplay_character)
	_play_next_level.call_deferred()

func _play_next_level():
	level = level_scene.instantiate()
	level.initialize(characters)
	level_parent.add_child(level, true)
	level.freeze(true)
	ui_layer.hud.set_characters(level.characters)
	ui_layer.hud.show_character_config(true)
	# Everything is set up, wait until all players are ready.
	
func _on_readiness_updated(character_idx: int, ready: bool):
	if ready:
		characters_ready[character_idx] = true
		if characters_ready.size() == characters.size():
			_start_level()
	else:
		characters_ready.erase(character_idx)
		
func _start_level():
	ui_layer.hud.show_character_config(false)
	level.freeze(false)
