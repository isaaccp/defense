@tool
extends Node

class_name XPComponent

const component = &"XPComponent"

enum LevelXPType {
	UNSPECIFIED,
	## Grants extra bonus experience if you finish the level
	## soon after the last spawn happens.
	TIME_SINCE_LAST_SPAWN,
}

# TIME_SINCE_LAST_SPAWN config.
# Less than 15s -> 2x XP, less than 30s -> 1.5x XP, less than 1m -> 1x XP,
# beyond that 0.5x XP.
const experience_time_2x = 15.0
const experience_time_1_5x = 30.0
const experience_time_1x = 60.0

@export_group("Required")
@export var level_xp_type: LevelXPType
@export var base_xp = 100
@export var characters: Node
@export var spawners: Node
@export var victory_loss_condition_component: VictoryLossConditionComponent

# TODO: Move to a single place if https://github.com/godotengine/godot-proposals/issues/6416 is implemented.
var running = false
var elapsed_time: float = 0.0
var counting_time = false

class GrantedXP extends RefCounted:
	var amount: int
	var text: String

var granted_xp: GrantedXP

func _ready():
	victory_loss_condition_component.level_finished.connect(_on_level_finished)

func run():
	if running:
		assert(false, "run() called twice on %s" % component)
	running = true
	match level_xp_type:
		LevelXPType.TIME_SINCE_LAST_SPAWN:
			for spawner in spawners.get_children():
				spawner.finished_spawning.connect(_on_finished_spawning)

func _process(delta: float):
	if not running:
		return
	if counting_time:
		elapsed_time += delta

func _on_finished_spawning():
	if _all_spawners_finished():
		# TODO: Show the timer somewhere?
		counting_time = true

func _all_spawners_finished() -> bool:
	for spawner in spawners.get_children():
		if not spawner.finished():
			return false
	return true

func _time_since_last_spawn_xp_string(granted: int, base: int, multiplier: float, time_str: String) -> String:
	return "Base XP: %d\nTime multiplier: %0.1f (finished within %s of last spawn)\nXP: %d" % [base, multiplier, time_str, granted]

func _on_level_finished(victory_type: VictoryLossConditionComponent.VictoryType):
	granted_xp = GrantedXP.new()
	match level_xp_type:
		LevelXPType.TIME_SINCE_LAST_SPAWN:
			counting_time = false
			if elapsed_time < experience_time_2x:
				granted_xp.amount = base_xp * 2
				granted_xp.text = _time_since_last_spawn_xp_string(granted_xp.amount, base_xp, 2, "< %ds" % experience_time_2x)
			elif elapsed_time < experience_time_1_5x:
				granted_xp.amount = base_xp * 1.5
				granted_xp.text = _time_since_last_spawn_xp_string(granted_xp.amount, base_xp, 1.5, "< %ds" % experience_time_1_5x)
			elif elapsed_time < experience_time_1x:
				granted_xp.amount = base_xp
				granted_xp.text = _time_since_last_spawn_xp_string(granted_xp.amount, base_xp, 1.0, "< %ds" % experience_time_1x)
			else:
				granted_xp.amount = base_xp * 0.5
				granted_xp.text = _time_since_last_spawn_xp_string(granted_xp.amount, base_xp, 0.5, "> %ds" % experience_time_1x)

func xp() -> GrantedXP:
	return granted_xp

static func get_or_null(node) -> XPComponent:
	return Component.get_or_null(node, component) as XPComponent

static func get_or_die(node) -> XPComponent:
	var c = get_or_null(node)
	assert(c)
	return c

func _get_configuration_warnings():
	var warnings = PackedStringArray()
	if not get_parent() is Node2D:
		return warnings
	# TODO
	return warnings


