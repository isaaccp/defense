extends Node

class_name VictoryLossConditionComponent

const component = &"VictoryLossConditionComponent"

enum VictoryType {
	UNSPECIFIED,
	KILL_ALL_ENEMIES,
	ONE_REACH_POSITION,
	ALL_REACH_POSITION,
	TIME,
}

enum LossType {
	UNSPECIFIED,
	ANY_CHARACTER_DIED,
	ALL_CHARACTERS_DIED,
	TOWER_DIED,
	TIME,
}

signal level_finished(victory_type: VictoryType)
signal level_failed(loss_type: LossType)

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
# Required if either timed victory or loss.
@export var time: float

@export_group("Debug")
@export var dead_characters = 0
@export var done = false

const position_check_interval = 0.25
var timer: SceneTreeTimer

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

func level_started():
	if VictoryType.TIME in victory or LossType.TIME in loss:
		assert(not is_zero_approx(time))
		var victory = VictoryType.TIME in victory
		timer = get_tree().create_timer(time, false)
		await timer.timeout.connect(
			func():
				if victory:
					_emit_victory(VictoryType.TIME)
				else:
					_emit_loss(LossType.TIME)
		)

func _start_position_check():
	var distance_squared = distance * distance
	while not done:
		await get_tree().create_timer(position_check_interval, false).timeout
		var count = 0
		for character in characters.get_children():
			if character.global_position.distance_squared_to(position.global_position) < distance_squared:
				if VictoryType.ONE_REACH_POSITION in victory:
					_emit_victory(VictoryType.ONE_REACH_POSITION)
					return
				count += 1
		if VictoryType.ALL_REACH_POSITION in victory:
			if count == characters.get_child_count():
				_emit_victory(VictoryType.ALL_REACH_POSITION)
				return

func _on_removing_enemy(node: Node):
	# TODO: Will need changes when we have spawners.
	# If this is the last enemy and it's dead, declare victory.
	if enemies.get_child_count() == 1:
		if Component.get_health_component_or_die(node).is_dead:
			_emit_victory(VictoryType.KILL_ALL_ENEMIES)

func _on_character_died():
	if LossType.ANY_CHARACTER_DIED in loss:
		_emit_loss(LossType.ANY_CHARACTER_DIED)
	elif LossType.ALL_CHARACTERS_DIED:
		dead_characters += 1
		if dead_characters == characters.get_child_count():
			_emit_loss(LossType.ALL_CHARACTERS_DIED)

func _on_tower_died():
	_emit_loss(LossType.TOWER_DIED)

func _emit_victory(victory_type: VictoryType):
	_emit(true, victory_type, LossType.UNSPECIFIED)

func _emit_loss(loss_type: LossType):
	_emit(false, VictoryType.UNSPECIFIED, loss_type)

func _emit(success: bool, victory_type: VictoryType, loss_type: LossType):
	# Do not emit more than once.
	if done:
		return
	if success:
		level_finished.emit(victory_type)
	else:
		level_failed.emit(loss_type)

#func get_text_victory_conditions() -> Array[String]:
	#var victory_conditions: Array[String] = []
	#for type in victory:
		#victory_conditions.append(get_text_victory_condition(type))
	#return victory_conditions

func get_text_victory_condition(victory_type: VictoryType) -> String:
	match victory_type:
		VictoryType.KILL_ALL_ENEMIES:
			return "Destroy all the enemies"
		# TODO: Somethign fancy for positions so we can highlight it in the map.
		VictoryType.ONE_REACH_POSITION:
			return "Have one character reach [hint='%s']target[/hint]" % position.name.capitalize()
		VictoryType.ALL_REACH_POSITION:
			return "Have all characters reach [hint='%s']target[/hint]" % position.name.capitalize()
		VictoryType.TIME:
			return "Time (%0.1fs) runs out" % time
	return "Unspecified"

func get_text_loss_condition(loss_type: LossType) -> String:
	match loss_type:
		LossType.ANY_CHARACTER_DIED:
			return "Any character dies"
		LossType.ALL_CHARACTERS_DIED:
			return "All characters die"
		LossType.TOWER_DIED:
			return "Tower dies"
		LossType.TIME:
			return "Time (%0.1fs) runs out" % time
	return "Unspecified"
static func victory_type_name(victory: VictoryType):
	return VictoryType.keys()[victory]

static func loss_type_name(loss: LossType):
	return LossType.keys()[loss]
