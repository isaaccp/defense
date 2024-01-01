extends Node2D

class_name Level

@export var characters: Node2D
@export var enemies: Node2D
@export var towers: Node2D
@export var starting_positions: Node

func initialize(gameplay_characters: Array[GameplayCharacter]):
	for i in gameplay_characters.size():
		var character = CharacterManager.make_character(gameplay_characters[i].character_id)
		character.idx = i
		character.peer_id = gameplay_characters[i].peer_id
		character.position = starting_positions.get_child(i).position
		characters.add_child(character)

func freeze(frozen: bool):
	_freeze_tree(characters, frozen)
	_freeze_tree(enemies, frozen)
	
func _freeze_node(node: Node, frozen: bool):
	node.set_process(!frozen)
	node.set_physics_process(!frozen)
	node.set_process_input(!frozen)
	node.set_process_internal(!frozen)
	node.set_process_unhandled_input(!frozen)
	node.set_process_unhandled_key_input(!frozen)

func _freeze_tree(node: Node, frozen: bool):
	_freeze_node(node, frozen)
	for c in node.get_children():
		_freeze_tree(c, frozen)
