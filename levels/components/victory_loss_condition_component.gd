extends Node

class_name VictoryLossConditionComponent

const component = &"VictoryLossConditionComponent"

enum VictoryType {
	UNSPECIFIED,
	KILL_ALL_ENEMIES,
	ONE_REACH_POSITION,
	ALL_REACH_POSITION,
}

enum LossType {
	UNSPECIFIED,
	ANY_CHARACTER_DIED,
	ALL_CHARACTERS_DIED,
	TOWER_DIED,
}

signal level_finished
signal level_failed

@export_group("Required")
@export var victory: Array[VictoryType] = [VictoryType.KILL_ALL_ENEMIES]
@export var loss: Array[LossType] = [LossType.ALL_CHARACTERS_DIED, LossType.TOWER_DIED]

@export_group("Optional")
# Node with characters. Required depending on types.
@export var characters: Node
# Node with tower. Required for failing level on tower destruction.
@export var towers: Node
# Required if type is KILL_ALL_ENEMIES.
@export var enemies: Node
# Required if type requires it.
@export var position: Node2D
# Distance from position for considering it reached.
@export var distance = 30

@export_group("Debug")
@export var dead_characters = 0
@export var done = false

func _ready():
	if VictoryType.KILL_ALL_ENEMIES in victory:
		assert(enemies)
		enemies.child_exiting_tree.connect(_on_removing_enemy)
	if VictoryType.ONE_REACH_POSITION in victory or VictoryType.ALL_REACH_POSITION in victory:
		assert(position)
		assert(characters)
		_start_position_check.call_deferred()
	if LossType.ANY_CHARACTER_DIED in loss or LossType.ALL_CHARACTERS_DIED in loss:
		assert(characters)
		for character in characters.get_children():
			var health = Component.get_health_component_or_die(character)
			health.died.connect(_on_character_died)
	if LossType.TOWER_DIED in loss:
		assert(towers)
		assert(towers.get_child_count() == 1)
		var tower = towers.get_child(0)
		var health_component = Component.get_health_component_or_die(tower)
		health_component.died.connect(_on_tower_died)
		
func _start_position_check():
	pass
	# TODO: Implement.
	
func _on_removing_enemy(node: Node):
	# TODO: Will need changes when we have spawners.
	# If this is the last enemy and it's dead, declare victory.
	if enemies.get_child_count() == 1:
		if Component.get_health_component_or_die(node).is_dead:
			_emit(true)

func _on_character_died():
	if LossType.ANY_CHARACTER_DIED in loss:
		_emit(false)
	elif LossType.ALL_CHARACTERS_DIED:
		dead_characters += 1
		if dead_characters == characters.get_child_count():
			_emit(false)

func _on_tower_died():
	_emit(false)

func _emit(success: bool):
	# Do not emit more than once.
	if done:
		return
	if success:
		level_finished.emit()
	else:
		level_failed.emit()
