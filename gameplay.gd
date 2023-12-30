extends Node2D

class_name Gameplay

@export_group("Internal")
@export var ui_layer: GameplayUILayer
@export var level_parent: Node2D

const level_scene = preload("res://levels/level.tscn")

var character_selections: Array[Enum.CharacterId]

func start():
	ui_layer.show()
	ui_layer.hud.set_peer(multiplayer.get_unique_id())
	ui_layer.character_selection_screen.set_characters(2)
	ui_layer.show_screen(ui_layer.character_selection_screen)

func _on_character_selection_screen_selection_ready(character_selections_: Array[Enum.CharacterId]):
	ui_layer.hide_screen()
	character_selections = character_selections_
	print(character_selections)
	_play_next_level.call_deferred()

func _play_next_level():
	var level = level_scene.instantiate()
	level.initialize(character_selections)
	level_parent.add_child(level, true)
