extends Node

# Runs a level headlessly for N simulated seconds, streams per-actor logs to
# stdout, and prints a short outcome summary. Leans on LoggingComponent
# (which already logs behavior/health/damage/etc.) rather than reimplementing
# tracking — the log stream is the report.
#
# Invoked by tools/playthrough.gd (a SceneTree bootstrap). Usage:
#   godot --headless --path . -s tools/playthrough.gd -- <level_path> [seconds=10] [log_types]
#
# log_types: comma-separated LoggingComponent.LogType names enabled on every
# actor. Use "all" for log_all=true (very verbose). Defaults to
# "BEHAVIOR,HEALTH" — readable and shows what enemies are doing + when they
# take damage. Examples:
#   ... -- res://levels/main/foo.tscn
#   ... -- res://levels/main/foo.tscn 15 BEHAVIOR,ACTION,DAMAGE
#   ... -- res://levels/main/foo.tscn 5 all

const test_character_res := preload("res://character/playable_characters/test_character.tres")
const DEFAULT_LOG_TYPES := "BEHAVIOR,HEALTH"

# Set by the bootstrap before add_child().
var scene_tree: SceneTree
var args: PackedStringArray

var _seconds: float = 10.0
var _log_all_flag := false
var _log_types: Array[LoggingComponent.LogType] = []

var _level: Level
var _elapsed := 0.0
var _started := false

var _enemies_spawned := 0
var _enemies_seen: Array[Enemy] = []
var _outcome := "still running (no victory/loss triggered)"

func _ready() -> void:
	if args.is_empty():
		print("Usage: godot --headless --path . -s tools/playthrough.gd -- <level_path> [seconds=10] [log_types]")
		scene_tree.quit(1)
		return
	# Reset the shared timeline so debug logs in this run start at 0.
	LoggingComponent.reset_origin()
	var path: String = args[0]
	if not path.begins_with("res://"):
		path = "res://" + path
	if args.size() > 1:
		_seconds = float(args[1])
	_parse_log_types(args[2] if args.size() > 2 else DEFAULT_LOG_TYPES)

	var packed := load(path) as PackedScene
	if not packed:
		push_error("Could not load: %s" % path)
		scene_tree.quit(1)
		return

	_level = packed.instantiate() as Level
	if not _level:
		push_error("Scene does not extend Level: %s" % path)
		scene_tree.quit(1)
		return
	_level.ready_to_fight_wait = 0.0  # skip "Fight!" intro wait
	# Parent the level under ourselves (a Node), not root — so its _ready
	# doesn't think it's standalone-F6.
	add_child(_level)

	var num := _level.starting_positions.get_child_count()
	var chars: Array[GameplayCharacter] = []
	for i in num:
		var gc := test_character_res.duplicate(true) as GameplayCharacter
		gc.acquired_skills = SkillTreeState.new()
		gc.acquired_skills.full = true
		gc.health = gc.attributes.health
		if not gc.behavior:
			gc.behavior = StoredBehavior.new()
		chars.append(gc)
	_level.initialize(chars)

	for spawner in _level.spawners.get_children():
		if spawner.has_signal("enemy_spawned"):
			spawner.enemy_spawned.connect(_on_enemy_spawned)

	_enable_logging(_level.characters)
	_enable_logging(_level.towers)
	# Enemies are enabled on spawn (see _on_enemy_spawned).

	var vl := Component.get_victory_loss_condition_component_or_die(_level) as VictoryLossConditionComponent
	vl.level_finished.connect(_on_level_finished)
	vl.level_failed.connect(_on_level_failed)

	print("=== Playthrough: %s for %.1fs ===" % [path, _seconds])
	_print_actors("Characters", _level.characters)
	_print_actors("Towers", _level.towers)
	print("--- logs ---")

	# PREPARE is entered via call_deferred from Level._ready(). Trigger the
	# transition to COMBAT on the next frame; _process starts counting once
	# COMBAT is actually active.
	call_deferred("_force_combat")

func _force_combat() -> void:
	_level._on_all_ready()

func _process(delta: float) -> void:
	if not _started:
		if _level and is_instance_valid(_level) and _level.state.is_state(_level.COMBAT):
			_started = true
		return
	_elapsed += delta
	if _elapsed >= _seconds or _level.state.is_state(_level.SUMMARY) or _level.state.is_state(_level.DONE):
		_finish()

# --- Setup helpers ---

func _parse_log_types(arg: String) -> void:
	var trimmed := arg.strip_edges()
	if trimmed.is_empty() or trimmed.to_lower() == "none":
		return
	if trimmed.to_lower() == "all":
		_log_all_flag = true
		return
	for entry in trimmed.split(","):
		var key := entry.strip_edges().to_upper()
		if LoggingComponent.LogType.keys().has(key):
			_log_types.append(LoggingComponent.LogType[key])
		else:
			push_warning("Unknown LogType '%s' — valid: %s" % [
				key, ", ".join(LoggingComponent.LogType.keys()),
			])

func _enable_logging(container: Node) -> void:
	for actor in container.get_children():
		_enable_logging_on(actor)

func _enable_logging_on(actor: Node) -> void:
	var log_comp: LoggingComponent = Component.get_or_null(actor, LoggingComponent.component)
	if not log_comp:
		return
	if _log_all_flag:
		log_comp.log_all = true
	for t in _log_types:
		if t not in log_comp.print_logtypes:
			log_comp.print_logtypes.append(t)

# --- Live tracking ---

func _on_enemy_spawned(enemy: Enemy) -> void:
	_enemies_spawned += 1
	_enemies_seen.append(enemy)
	_enable_logging_on(enemy)

func _on_level_finished(v: int) -> void:
	_outcome = "victory (%s)" % VictoryLossConditionComponent.VictoryType.keys()[v]

func _on_level_failed(l: int) -> void:
	_outcome = "loss (%s)" % VictoryLossConditionComponent.LossType.keys()[l]

# --- Reporting ---

func _print_actors(label: String, container: Node) -> void:
	print("%s (%d):" % [label, container.get_child_count()])
	for actor in container.get_children():
		print("  %s @ (%d, %d)" % [actor.actor_name, actor.position.x, actor.position.y])

func _finish() -> void:
	if _level.state.is_state(_level.COMBAT):
		_level.stop()
	print("--- end of logs ---")
	print("Summary (after %.1fs, outcome: %s):" % [_elapsed, _outcome])
	var alive_enemies: Array[Enemy] = []
	for e in _enemies_seen:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			alive_enemies.append(e)
	print("  Enemies: %d spawned, %d alive, %d dead" % [
		_enemies_spawned, alive_enemies.size(), _enemies_spawned - alive_enemies.size(),
	])
	_print_alive("Characters", _level.characters)
	_print_alive("Towers", _level.towers)
	_print_alive_list("Enemies (alive)", alive_enemies)
	scene_tree.quit(0)

func _print_alive(label: String, container: Node) -> void:
	var alive: Array = []
	for actor in container.get_children():
		if is_instance_valid(actor) and not actor.is_queued_for_deletion():
			alive.append(actor)
	_print_alive_list(label, alive)

func _print_alive_list(label: String, actors: Array) -> void:
	print("  %s: %d" % [label, actors.size()])
	for actor in actors:
		print("    %s @ (%d, %d)" % [actor.actor_name, actor.position.x, actor.position.y])
