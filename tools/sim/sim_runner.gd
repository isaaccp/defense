extends Node

# Headless single-level simulator. Reads a JSON config, builds characters
# with specified skills + behaviors, runs the level for up to N seconds,
# and writes a JSON summary next to the config.
#
# See tools/sim/SIM.md for the full design, config/behavior/summary schemas,
# and rationale. Invoked by tools/sim/sim.gd (bootstrap).

const SKILL_TREE_DIRS := [
	"res://skill_tree/actions",
	"res://skill_tree/conditions",
	"res://skill_tree/targets",
	"res://skill_tree/target_sorts",
	"res://skill_tree/meta_skills",
]

# Map JSON cmp strings to SkillParams.CmpOp enum.
const CMP_MAP := {
	"<": SkillParams.CmpOp.LT,
	"<=": SkillParams.CmpOp.LE,
	"=": SkillParams.CmpOp.EQ,
	"==": SkillParams.CmpOp.EQ,
	">=": SkillParams.CmpOp.GE,
	">": SkillParams.CmpOp.GT,
	"LT": SkillParams.CmpOp.LT,
	"LE": SkillParams.CmpOp.LE,
	"EQ": SkillParams.CmpOp.EQ,
	"GE": SkillParams.CmpOp.GE,
	"GT": SkillParams.CmpOp.GT,
}

# Set by the bootstrap before add_child().
var scene_tree: SceneTree
var args: PackedStringArray

var _config: Dictionary
var _config_path: String
var _level: Level
var _max_seconds: float
var _elapsed := 0.0
var _started := false
var _finished := false

var _enemies_spawned := 0
var _enemies_seen: Array[Enemy] = []
var _outcome := "timeout"
var _victory_type: String = ""
var _loss_type: String = ""
# actor_name (with idx suffix if duplicated) -> { killed_by: String, at: Vector2 }
var _killed_by: Dictionary = {}
# High-signal "story of the run" events for scanning before raw logs.
# Each entry: {t: float, kind: String, ...payload}
var _events: Array = []
# Per-actor HP milestone tracking to avoid re-emitting the same threshold.
var _hp_milestones_fired: Dictionary = {}

func _ready() -> void:
	if args.is_empty():
		_fail("Usage: godot --headless --path . -s tools/sim/sim.gd -- <config.json>")
		return
	_config_path = args[0]
	if _config_path.begins_with("res://"):
		_config_path = ProjectSettings.globalize_path(_config_path)
	if not _load_config():
		return
	if not _validate_config():
		return
	LoggingComponent.reset_origin()

	var level_path: String = _config.get("level", "")
	var packed := load(level_path) as PackedScene
	if not packed:
		_fail("could not load level: %s" % level_path)
		return

	_level = packed.instantiate() as Level
	if not _level:
		_fail("scene does not extend Level: %s" % level_path)
		return
	_level.ready_to_fight_wait = 0.0
	add_child(_level)

	_max_seconds = float(_config.get("max_seconds", 30))

	var characters_cfg: Array = _config.get("characters", [])
	var chars: Array[GameplayCharacter] = []
	for i in characters_cfg.size():
		var gc := _build_character(characters_cfg[i], i)
		if not gc:
			return  # _fail already called
		chars.append(gc)
	_level.initialize(chars)

	# Apply per-character position overrides after initialize() placed them
	# at StartingPositions.
	for i in characters_cfg.size():
		var pos = characters_cfg[i].get("starting_position")
		if pos != null:
			_level.characters.get_child(i).position = _to_vector2(pos)

	# Enable BEHAVIOR + HEALTH logging on all actors so the run is readable.
	for actor in _level.characters.get_children():
		_enable_logging(actor)
		_hook_death_attribution(actor)
		_hook_hp_milestones(actor)
	for actor in _level.towers.get_children():
		_enable_logging(actor)
		_hook_death_attribution(actor)
		_hook_hp_milestones(actor)

	for spawner in _level.spawners.get_children():
		if spawner.has_signal("enemy_spawned"):
			spawner.enemy_spawned.connect(_on_enemy_spawned)

	var vl := Component.get_victory_loss_condition_component_or_die(_level) as VictoryLossConditionComponent
	vl.level_finished.connect(_on_level_finished)
	vl.level_failed.connect(_on_level_failed)

	print("=== Sim: %s (max %.1fs) ===" % [_config_path, _max_seconds])
	print("Level: %s" % level_path)
	print("Characters:")
	for actor in _level.characters.get_children():
		print("  %s @ (%d, %d)" % [actor.actor_name, actor.position.x, actor.position.y])
	print("--- logs ---")
	call_deferred("_force_combat")

func _force_combat() -> void:
	_level._on_all_ready()

func _process(delta: float) -> void:
	if _finished:
		return
	if not _started:
		if _level and is_instance_valid(_level) and _level.state.is_state(_level.COMBAT):
			_started = true
		return
	_elapsed += delta
	if _elapsed >= _max_seconds:
		_finish()
		return
	if _level.state.is_state(_level.SUMMARY) or _level.state.is_state(_level.DONE):
		_finish()

# --- Config loading ---

func _validate_config() -> bool:
	# Pre-flight: walk the whole config and collect every issue, so the user
	# sees all problems at once instead of fix-rerun-fix-rerun. Catches missing
	# paths, unknown skill basenames, and behaviors that reference skills the
	# character hasn't acquired.
	var errors: PackedStringArray = []
	var level: String = _config.get("level", "")
	if level.is_empty():
		errors.append("config missing 'level' field")
	elif not ResourceLoader.exists(level):
		errors.append("level not found: %s" % level)
	var characters_cfg: Array = _config.get("characters", [])
	if characters_cfg.is_empty():
		errors.append("config has no characters")
	for i in characters_cfg.size():
		var cfg: Dictionary = characters_cfg[i]
		var prefix := "characters[%d]" % i
		var char_path: String = cfg.get("character", "")
		if char_path.is_empty():
			errors.append("%s missing 'character' field" % prefix)
		elif not ResourceLoader.exists(char_path):
			errors.append("%s: character not found: %s" % [prefix, char_path])
		# Skills resolution + collect the resolved set for behavior cross-check.
		var acquired = cfg.get("acquired_skills", [])
		var acquired_set: Dictionary = {}
		var has_all_skills := false
		if typeof(acquired) == TYPE_STRING:
			if acquired == "full":
				has_all_skills = true
			else:
				errors.append("%s: acquired_skills must be array or 'full', got '%s'" % [prefix, acquired])
		elif typeof(acquired) == TYPE_ARRAY:
			for basename in acquired:
				var skill_name := _resolve_skill_basename(basename)
				if skill_name == &"":
					errors.append("%s: skill basename '%s' not found in %s" % [prefix, basename, ", ".join(SKILL_TREE_DIRS)])
				else:
					acquired_set[skill_name] = true
		else:
			errors.append("%s: acquired_skills must be array or 'full'" % prefix)
		# Behavior.
		var behavior_path: String = cfg.get("behavior", "")
		if not behavior_path.is_empty():
			_validate_behavior_file(behavior_path, acquired_set, has_all_skills, prefix, errors)
	if errors.is_empty():
		return true
	push_error("Config validation failed:\n  - %s" % "\n  - ".join(errors))
	scene_tree.quit(1)
	return false

# Walks a behavior JSON file and records issues against `errors`. Resolves
# every skill reference via SkillManager and checks it's in the character's
# acquired set (or all_skills if "full").
func _validate_behavior_file(path: String, acquired: Dictionary, full: bool, prefix: String, errors: PackedStringArray) -> void:
	var abs := ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
	var f := FileAccess.open(abs, FileAccess.READ)
	if not f:
		errors.append("%s: behavior file not found: %s" % [prefix, path])
		return
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		errors.append("%s: behavior is not a JSON object: %s" % [prefix, path])
		return
	var rules: Array = parsed.get("rules", [])
	for i in rules.size():
		var rule = rules[i]
		var rule_prefix := "%s behavior %s rule[%d]" % [prefix, path.get_file(), i]
		for field in ["action", "target", "condition"]:
			_validate_skill_ref(rule.get(field), field, rule_prefix, acquired, full, errors)
		# `sort` is optional; if present validate it.
		if rule.has("sort") and rule.get("sort") != null:
			_validate_skill_ref(rule.get("sort"), "sort", rule_prefix, acquired, full, errors)

func _validate_skill_ref(ref: Variant, field: String, prefix: String, acquired: Dictionary, full: bool, errors: PackedStringArray) -> void:
	if typeof(ref) != TYPE_DICTIONARY:
		errors.append("%s.%s must be an object with 'name'" % [prefix, field])
		return
	var name = ref.get("name", "")
	if typeof(name) != TYPE_STRING or name.is_empty():
		errors.append("%s.%s missing 'name'" % [prefix, field])
		return
	var skill := SkillManager.lookup_skill(StringName(name))
	if not skill:
		errors.append("%s.%s: unknown skill '%s'" % [prefix, field, name])
		return
	if not full and not acquired.has(StringName(name)):
		errors.append("%s.%s: skill '%s' is referenced but not in character's acquired_skills" % [prefix, field, name])

func _load_config() -> bool:
	var f := FileAccess.open(_config_path, FileAccess.READ)
	if not f:
		_fail("could not open config: %s" % _config_path)
		return false
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_fail("config is not a JSON object: %s" % _config_path)
		return false
	_config = parsed
	return true

# --- Character building ---

func _build_character(cfg: Dictionary, idx: int) -> GameplayCharacter:
	var char_path: String = cfg.get("character", "")
	if char_path.is_empty():
		_fail("character #%d missing 'character' field" % idx)
		return null
	var gc := load(char_path) as GameplayCharacter
	if not gc:
		_fail("could not load character: %s" % char_path)
		return null
	gc = gc.duplicate(true)

	gc.acquired_skills = _build_skill_tree_state(cfg.get("acquired_skills", []), idx)
	if not gc.acquired_skills:
		return null

	var behavior_path: String = cfg.get("behavior", "")
	if behavior_path.is_empty():
		gc.behavior = StoredBehavior.new()
	else:
		var behavior := _load_behavior_json(behavior_path)
		if not behavior:
			return null  # _fail already called
		gc.behavior = behavior

	var starting_health = cfg.get("starting_health")
	if starting_health != null:
		gc.health = int(starting_health)
	else:
		gc.health = gc.attributes.health

	return gc

func _build_skill_tree_state(skills_cfg: Variant, char_idx: int) -> SkillTreeState:
	var state := SkillTreeState.new()
	if typeof(skills_cfg) == TYPE_STRING and skills_cfg == "full":
		state.full = true
		return state
	if typeof(skills_cfg) != TYPE_ARRAY:
		_fail("character #%d acquired_skills must be array or 'full'" % char_idx)
		return null
	var names: Array[StringName] = []
	for basename in skills_cfg:
		var skill_name := _resolve_skill_basename(basename)
		if skill_name == &"":
			_fail("character #%d: skill basename '%s' not found in %s" % [
				char_idx, basename, ", ".join(SKILL_TREE_DIRS),
			])
			return null
		names.append(skill_name)
	state.skills = names
	return state

func _resolve_skill_basename(basename: String) -> StringName:
	for dir in SKILL_TREE_DIRS:
		var path := "%s/%s.tres" % [dir, basename]
		if ResourceLoader.exists(path):
			var skill := load(path) as Skill
			if skill:
				return skill.skill_name
	return &""

# --- Behavior JSON translation ---

func _load_behavior_json(path: String) -> StoredBehavior:
	var abs_path := path
	if path.begins_with("res://"):
		abs_path = ProjectSettings.globalize_path(path)
	var f := FileAccess.open(abs_path, FileAccess.READ)
	if not f:
		_fail("could not open behavior: %s" % path)
		return null
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_fail("behavior is not a JSON object: %s" % path)
		return null
	var rules_cfg: Array = parsed.get("rules", [])
	var behavior := StoredBehavior.new()
	behavior.name = parsed.get("name", path.get_file().get_basename())
	for i in rules_cfg.size():
		var rule := _build_rule(rules_cfg[i], i, path)
		if not rule:
			return null
		behavior.stored_rules.append(rule)
	return behavior

func _build_rule(cfg: Dictionary, idx: int, path: String) -> RuleDef:
	var action_sps := _build_stored_param_skill(cfg.get("action"), Skill.SkillType.ACTION, "action", idx, path)
	if not action_sps:
		return null
	var target_sps := _build_stored_param_skill(cfg.get("target"), Skill.SkillType.TARGET, "target", idx, path)
	if not target_sps:
		return null
	# Sort lives inside target's params (placeholder SORT). If specified, set it.
	var sort_cfg = cfg.get("sort")
	if sort_cfg != null:
		var sort_skill := _resolve_skill_object(sort_cfg, Skill.SkillType.TARGET_SORT, "sort", idx, path)
		if not sort_skill:
			return null
		target_sps.params.sort = StoredSkill.from_skill(sort_skill)
	var condition_sps := _build_stored_param_skill(cfg.get("condition"), Skill.SkillType.CONDITION, "condition", idx, path)
	if not condition_sps:
		return null
	return RuleDef.make(target_sps, action_sps, condition_sps)

func _build_stored_param_skill(cfg: Variant, expected_type: int, field: String, rule_idx: int, path: String) -> StoredParamSkill:
	if typeof(cfg) != TYPE_DICTIONARY:
		_fail("%s rule #%d.%s must be an object with 'name'" % [path, rule_idx, field])
		return null
	var skill := _resolve_skill_object(cfg, expected_type, field, rule_idx, path)
	if not skill:
		return null

	var sps := StoredParamSkill.new()
	sps.name = skill.skill_name
	sps.skill_type = skill.skill_type

	var params := SkillParams.new()
	# Copy the editor_string template from the skill so the runtime can
	# interpolate placeholders correctly.
	if skill is ParamSkill and (skill as ParamSkill).params:
		params.editor_string = (skill as ParamSkill).params.editor_string

	var params_cfg = cfg.get("params", {})
	if typeof(params_cfg) == TYPE_DICTIONARY:
		if not _apply_params(params, params_cfg, field, rule_idx, path):
			return null
	sps.params = params
	return sps

func _resolve_skill_object(cfg: Variant, expected_type: int, field: String, rule_idx: int, path: String) -> Skill:
	if typeof(cfg) != TYPE_DICTIONARY:
		_fail("%s rule #%d.%s must be an object with 'name'" % [path, rule_idx, field])
		return null
	var name = cfg.get("name", "")
	if typeof(name) != TYPE_STRING or name.is_empty():
		_fail("%s rule #%d.%s missing 'name'" % [path, rule_idx, field])
		return null
	var skill := SkillManager.lookup_skill(StringName(name))
	if not skill:
		_fail("%s rule #%d.%s: unknown skill '%s'" % [path, rule_idx, field, name])
		return null
	if skill.skill_type != expected_type:
		_fail("%s rule #%d.%s: skill '%s' is %s, expected %s" % [
			path, rule_idx, field, name,
			Skill.SkillType.keys()[skill.skill_type],
			Skill.SkillType.keys()[expected_type],
		])
		return null
	return skill

func _apply_params(params: SkillParams, cfg: Dictionary, field: String, rule_idx: int, path: String) -> bool:
	for key in cfg.keys():
		var v = cfg[key]
		match key:
			"cmp":
				if not CMP_MAP.has(v):
					_fail("%s rule #%d.%s: unknown cmp '%s' (use <, <=, =, >=, >)" % [path, rule_idx, field, v])
					return false
				params.cmp = CMP_MAP[v]
			"int_value":
				params.int_value = IntValue.make(int(v))
			"float_value":
				params.float_value = FloatValue.make(float(v))
			"sort":
				# Allow sort inside params too, for symmetry with placeholder
				# names. Same effect as the rule-level sort field.
				var sort_skill := _resolve_skill_object(v, Skill.SkillType.TARGET_SORT, "params.sort", rule_idx, path)
				if not sort_skill:
					return false
				params.sort = StoredSkill.from_skill(sort_skill)
			_:
				push_warning("%s rule #%d.%s: unknown param key '%s'" % [path, rule_idx, field, key])
	return true

# --- Logging ---

func _enable_logging(actor: Node) -> void:
	var log_comp: LoggingComponent = Component.get_or_null(actor, LoggingComponent.component)
	if not log_comp:
		return
	for t in [
		LoggingComponent.LogType.BEHAVIOR,
		LoggingComponent.LogType.HEALTH,
		LoggingComponent.LogType.DEATH,
	]:
		if t not in log_comp.print_logtypes:
			log_comp.print_logtypes.append(t)

# --- Outcome tracking ---

# Connect to the actor's DeathHandlerComponent so we can snapshot the last
# attacker before queue_free runs (towers free on death; chars don't, but we
# use the same path for consistency).
func _hook_death_attribution(actor: Node) -> void:
	var dhc: DeathHandlerComponent = Component.get_or_null(actor, DeathHandlerComponent.component)
	if not dhc:
		return
	dhc.died.connect(_on_actor_died.bind(actor))

func _on_actor_died(actor: Node) -> void:
	var log_comp: LoggingComponent = Component.get_or_null(actor, LoggingComponent.component)
	var killer := ""
	if log_comp:
		# Last HURT entry's message format: "<attacker>'s <hitbox> ..."
		for i in range(log_comp.entries.size() - 1, -1, -1):
			var entry: LoggingComponent.LogEntry = log_comp.entries[i]
			if entry.type == LoggingComponent.LogType.HURT:
				var msg := entry.message as String
				var split := msg.find("'s ")
				if split > 0:
					killer = msg.substr(0, split)
				break
	# Snapshot the full per-actor row here — for towers and any actor with
	# free_on_death=true, this is the last chance to read its stats and
	# vitals before queue_free runs.
	var v: VitalsComponent = Component.get_or_null(actor, VitalsComponent.component)
	var max_hp := v.get_vital_max(VitalsComponent.VitalType.HEALTH) if v else 0.0
	_add_event("death", {
		"actor": actor.actor_name,
		"actor_key": _actor_key(actor),
		"killed_by": killer,
		"at": {"x": int(actor.position.x), "y": int(actor.position.y)},
	})
	_killed_by[_actor_key(actor)] = {
		"killed_by": killer,
		"at": {"x": int(actor.position.x), "y": int(actor.position.y)},
		"container": actor.get_parent().name,
		"snapshot": {
			"name": actor.actor_name,
			"hp_final": 0.0,
			"hp_max": snappedf(max_hp, 0.1),
			"alive": false,
			"position": {"x": int(actor.position.x), "y": int(actor.position.y)},
			"damage_dealt": int(log_comp.stats.get_value(Stat.DamageDealt)) if log_comp else 0,
			"damage_healed": int(log_comp.stats.get_value(Stat.DamageHealed)) if log_comp else 0,
			"enemies_killed": int(log_comp.stats.get_value(Stat.EnemiesDestroyed)) if log_comp else 0,
			"killed_by": killer,
			"death_position": {"x": int(actor.position.x), "y": int(actor.position.y)},
		},
	}

func _actor_key(actor: Node) -> String:
	# actor_name may collide (e.g. two Godricks). Suffix with the node path
	# index under its parent so the key is unique within the summary.
	var parent := actor.get_parent()
	for i in parent.get_child_count():
		if parent.get_child(i) == actor:
			return "%s#%d" % [actor.actor_name, i]
	return actor.actor_name

func _on_enemy_spawned(enemy: Enemy) -> void:
	_enemies_spawned += 1
	_enemies_seen.append(enemy)
	_enable_logging(enemy)
	_hook_death_attribution(enemy)
	_add_event("spawn", {
		"actor": enemy.actor_name,
		"actor_key": _actor_key(enemy),
		"at": {"x": int(enemy.position.x), "y": int(enemy.position.y)},
	})

func _on_level_finished(v: int) -> void:
	_outcome = "victory"
	_victory_type = VictoryLossConditionComponent.VictoryType.keys()[v]
	_add_event("victory", {"victory_type": _victory_type})

func _on_level_failed(l: int) -> void:
	_outcome = "loss"
	_loss_type = VictoryLossConditionComponent.LossType.keys()[l]
	_add_event("loss", {"loss_type": _loss_type})

func _add_event(kind: String, payload: Dictionary = {}) -> void:
	var ev := {"t": snappedf(_elapsed, 0.01), "kind": kind}
	for k in payload:
		ev[k] = payload[k]
	_events.append(ev)

func _hook_hp_milestones(actor: Node) -> void:
	var v: VitalsComponent = Component.get_or_null(actor, VitalsComponent.component)
	if not v:
		return
	v.vital_updated.connect(_on_vital_updated.bind(actor))

func _on_vital_updated(update: VitalsComponent.VitalUpdate, actor: Node) -> void:
	if update.type != VitalsComponent.VitalType.HEALTH:
		return
	if update.max_value <= 0:
		return
	var pct: float = update.current_value / update.max_value * 100.0
	var key := _actor_key(actor)
	var fired: Dictionary = _hp_milestones_fired.get(key, {})
	for threshold in [50, 25]:
		if pct <= threshold and not fired.has(threshold):
			fired[threshold] = true
			_add_event("low_hp", {
				"actor": actor.actor_name,
				"actor_key": key,
				"hp_pct": threshold,
				"at": {"x": int(actor.position.x), "y": int(actor.position.y)},
			})
	_hp_milestones_fired[key] = fired

# --- Reporting ---

func _finish() -> void:
	if _finished:
		return
	_finished = true
	if _level.state.is_state(_level.COMBAT):
		_level.stop()
	print("--- end of logs ---")

	var summary := {
		"config_path": _config_path,
		"notes": _config.get("notes", ""),
		"config": _config,
		"outcome": _outcome,
		"victory_type": _victory_type if _outcome == "victory" else null,
		"loss_type": _loss_type if _outcome == "loss" else null,
		"elapsed_seconds": snappedf(_elapsed, 0.01),
		"characters": _summarize_actors(_level.characters),
		"towers": _summarize_actors(_level.towers),
		"enemies": _summarize_enemies(),
		"xp_gained": _xp_gained(),
		"events": _events,
	}

	var summary_path := _summary_path_for(_config_path)
	var f := FileAccess.open(summary_path, FileAccess.WRITE)
	if not f:
		push_error("could not write summary: %s" % summary_path)
	else:
		f.store_string(JSON.stringify(summary, "  "))
		f.close()
		print("Summary: %s" % summary_path)
		print("Outcome: %s%s in %.1fs" % [
			_outcome,
			" (%s)" % (_victory_type if _outcome == "victory" else _loss_type) if _outcome != "timeout" else "",
			_elapsed,
		])

	scene_tree.quit(0)

func _summary_path_for(config_path: String) -> String:
	# Strip the trailing .json extension if present so we get
	# foo.summary.json from foo.json.
	if config_path.ends_with(".json"):
		return config_path.substr(0, config_path.length() - 5) + ".summary.json"
	return config_path + ".summary.json"

func _summarize_actors(container: Node) -> Array:
	# Walks both alive actors (still in the container) AND dead actors that
	# were free'd on death (their pre-death snapshot lives in _killed_by,
	# tagged with the container name).
	var out: Array = []
	var seen_keys: Dictionary = {}
	for actor in container.get_children():
		var key := _actor_key(actor)
		seen_keys[key] = true
		var v: VitalsComponent = Component.get_or_null(actor, VitalsComponent.component)
		var hp := v.get_vital_current(VitalsComponent.VitalType.HEALTH) if v else 0.0
		var max_hp := v.get_vital_max(VitalsComponent.VitalType.HEALTH) if v else 0.0
		var log_comp: LoggingComponent = Component.get_or_null(actor, LoggingComponent.component)
		var alive := is_instance_valid(actor) and not actor.is_queued_for_deletion() and hp > 0
		var entry := {
			"name": actor.actor_name,
			"hp_final": snappedf(hp, 0.1),
			"hp_max": snappedf(max_hp, 0.1),
			"alive": alive,
			"position": {"x": int(actor.position.x), "y": int(actor.position.y)},
			"damage_dealt": int(log_comp.stats.get_value(Stat.DamageDealt)) if log_comp else 0,
			"damage_healed": int(log_comp.stats.get_value(Stat.DamageHealed)) if log_comp else 0,
			"enemies_killed": int(log_comp.stats.get_value(Stat.EnemiesDestroyed)) if log_comp else 0,
		}
		if not alive:
			var attrib = _killed_by.get(key)
			if attrib:
				entry["killed_by"] = attrib.killed_by
				entry["death_position"] = attrib.at
		out.append(entry)
	# Append snapshots for actors that were free'd before we got here.
	for key in _killed_by:
		if seen_keys.has(key):
			continue
		var attrib = _killed_by[key]
		if attrib.get("container") == container.name:
			out.append(attrib.snapshot)
	return out

func _summarize_enemies() -> Dictionary:
	var alive: Array = []
	for e in _enemies_seen:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			alive.append({
				"name": e.actor_name,
				"position": {"x": int(e.position.x), "y": int(e.position.y)},
			})
	return {
		"spawned": _enemies_spawned,
		"killed": _enemies_spawned - alive.size(),
		"alive_final": alive,
	}

func _xp_gained() -> int:
	var xp_comp := XPComponent.get_or_null(_level)
	if not xp_comp:
		return 0
	var xp = xp_comp.xp()
	return xp.amount if xp else 0

# --- Helpers ---

func _to_vector2(v: Variant) -> Vector2:
	if typeof(v) == TYPE_DICTIONARY:
		return Vector2(float(v.get("x", 0)), float(v.get("y", 0)))
	if typeof(v) == TYPE_ARRAY and v.size() >= 2:
		return Vector2(float(v[0]), float(v[1]))
	return Vector2.ZERO

func _fail(msg: String) -> void:
	push_error(msg)
	if scene_tree:
		scene_tree.quit(1)
