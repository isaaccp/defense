extends Node2D

class_name Level

@export var xp: int = 100

@export_group("Tutorial")
# To be used for e.g. tutorial levels in which we may
# want a particular set of skills acquired/unlocked.
# Replaces skill tree state.
@export var skill_tree_state_override: SkillTreeState
# Same as above, but it only adds to existing tree, so
# it's less work if you don't need to remove skills.
@export var skill_tree_state_add: SkillTreeState

@export_group("Testing")
# For testing long level flows, instantly wins level.
@export var instant_win = false

@export_group("Internal")
@export var characters: Node2D
@export var enemies: Node2D
@export var towers: Node2D
@export var starting_positions: Node
var is_frozen: bool = false

func initialize(gameplay_characters: Array[GameplayCharacter]):
	for i in gameplay_characters.size():
		if skill_tree_state_add:
			gameplay_characters[i].skill_tree_state.add(skill_tree_state_add)
		if skill_tree_state_override:
			gameplay_characters[i].skill_tree_state = skill_tree_state_override
		var character = CharacterManager.make_character(gameplay_characters[i])
		character.idx = i
		character.peer_id = gameplay_characters[i].peer_id
		character.position = starting_positions.get_child(i).position
		characters.add_child(character)

func start():
	freeze(false)
	var victory_loss = Component.get_victory_loss_condition_component_or_die(self)
	if instant_win:
		victory_loss.victory.append(VictoryLossConditionComponent.VictoryType.TIME)
		victory_loss.time = 0.1
	# TODO: Maybe instead make a component that handles freeze/unfreeze
	# and can then be passed to VictoryLoss.
	victory_loss.level_started()

func freeze(frozen: bool):
	is_frozen = frozen
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
