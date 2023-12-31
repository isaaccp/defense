extends Node2D

class_name Level

@export var characters: Node2D
@export var enemies: Node2D
@export var towers: Node2D
@export var starting_positions: Node

@export_group("Testing")
# It can be set to false for tests.
@export var require_tower = true

signal level_finished
signal level_failed

var tower: Node2D

func initialize(gameplay_characters: Array[GameplayCharacter]):
	for i in gameplay_characters.size():
		var character = CharacterManager.make_character(gameplay_characters[i].character_id)
		character.idx = i
		character.peer_id = gameplay_characters[i].peer_id
		character.position = starting_positions.get_child(i).position
		characters.add_child(character)

func _ready():
	if require_tower:
		tower = towers.get_child(0)
		assert(tower, "Tower not found")
		var health_component = Component.get_health_component_or_die(tower)
		health_component.died.connect(_on_tower_died)
	enemies.child_exiting_tree.connect(_on_removing_enemy)
	
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

func _on_tower_died():
	level_failed.emit()

func _on_removing_enemy(node: Node):
	# If this is the last enemy and it's dead, declare victory.
	if enemies.get_child_count() == 1:
		if Component.get_health_component_or_die(node).is_dead:
			level_finished.emit()
