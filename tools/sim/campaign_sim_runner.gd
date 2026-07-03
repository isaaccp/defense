extends Node

# Headless multi-stage campaign simulator runner.
# Parsed from campaign_sim.gd.

const main_levels_provider = preload("res://levels/main/main_levels.tres")

const SKILL_TREE_DIRS := [
	"res://skill_tree/actions",
	"res://skill_tree/conditions",
	"res://skill_tree/targets",
	"res://skill_tree/target_sorts",
	"res://skill_tree/meta_skills",
]

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

var scene_tree: SceneTree
var args: PackedStringArray

var _level: Level
var _elapsed := 0.0
var _started := false
var _finished := false
var _outcome := "timeout"
var _save_path: String

func _ready() -> void:
	var action := ""
	var characters_str := ""
	var run_seed := 0
	var behaviors_str := ""
	var path_idx := -1
	var relic_recipient := ""
	var train_str := ""
	var save_path := "res://tools/sim/campaign_save.tres"

	for arg in args:
		if arg.begins_with("--action="):
			action = arg.split("=")[1]
		elif arg.begins_with("--characters="):
			characters_str = arg.split("=")[1]
		elif arg.begins_with("--seed="):
			run_seed = int(arg.split("=")[1])
		elif arg.begins_with("--behaviors="):
			behaviors_str = arg.split("=")[1]
		elif arg.begins_with("--path_idx="):
			path_idx = int(arg.split("=")[1])
		elif arg.begins_with("--relic_recipient="):
			relic_recipient = arg.split("=")[1]
		elif arg.begins_with("--train="):
			train_str = arg.split("=")[1]
		elif arg.begins_with("--save_path="):
			save_path = arg.split("=")[1]

	if save_path.begins_with("res://"):
		save_path = ProjectSettings.globalize_path(save_path)
	_save_path = save_path

	match action:
		"start":
			_run_start(characters_str, run_seed, save_path)
		"play_level":
			_run_play_level(behaviors_str, save_path)
		"claim_reward":
			_run_claim_reward(path_idx, relic_recipient, train_str, save_path)
		_:
			_fail("Unknown action '%s'. Supported actions: start, play_level, claim_reward" % action)

func _run_start(characters_str: String, run_seed: int, save_path: String) -> void:
	if characters_str.is_empty():
		_fail("Missing --characters=<names>")
		return
	if run_seed == 0:
		_fail("Missing or invalid --seed=<number>")
		return

	var run_start_skills = SkillTreeState.new()
	run_start_skills.add_skill_names(Constants.base_acquired_skills)

	var char_names = characters_str.split(",")
	var gcs: Array[GameplayCharacter] = []
	for i in range(char_names.size()):
		var char_path = _character_path_for(char_names[i].strip_edges())
		if char_path.is_empty():
			_fail("Unknown character: %s" % char_names[i])
			return
		var gc = load(char_path).duplicate(true) as GameplayCharacter
		gc.initialize(gc.name, i, StoredBehavior.new(), run_start_skills)
		# Clear starting relics/state for clean start
		gc.relics.clear()
		gc.relic_state.clear()
		gc.xp = 0
		gc.health = gc.attributes.health
		gcs.append(gc)

	var empty_progress: Dictionary[StringName, int] = {}
	var rss = RunSaveState.make(gcs, main_levels_provider, run_start_skills, {}, empty_progress)
	rss.seed = run_seed
	rss.reward_schedule = rss._generate_schedule(rss, main_levels_provider, run_start_skills)

	var err = ResourceSaver.save(rss, save_path)
	if err != OK:
		_fail("Failed to save run state to %s: error %d" % [save_path, err])
		return

	var level_scene = _pick_fight_level(rss)
	_append_log("Campaign run started. Seed: %d, Save: %s" % [run_seed, save_path], true)
	_append_log("Next Stage: 1, Level: %s" % level_scene.resource_path.get_file().get_basename())
	scene_tree.quit(0)

func _run_play_level(behaviors_str: String, save_path: String) -> void:
	if not FileAccess.file_exists(save_path):
		_fail("Save file not found at %s. Please run start action first." % save_path)
		return
	var rss := load(save_path) as RunSaveState
	if not rss:
		_fail("Failed to load RunSaveState from %s" % save_path)
		return

	if rss.current_phase != RunSaveState.Phase.FIGHT:
		_fail("Current phase is REWARD. Please claim rewards first.")
		return

	if behaviors_str.is_empty():
		_fail("Missing --behaviors=<path1,path2>")
		return

	var behavior_paths = behaviors_str.split(",")
	if behavior_paths.size() != rss.gameplay_characters.size():
		_fail("Number of behavior paths (%d) does not match number of characters (%d)" % [behavior_paths.size(), rss.gameplay_characters.size()])
		return

	for i in range(rss.gameplay_characters.size()):
		var bh_path = behavior_paths[i].strip_edges()
		var behavior = _load_behavior_cfg(bh_path)
		if not behavior:
			_fail("Failed to load behavior from %s" % bh_path)
			return
		rss.gameplay_characters[i].behavior = behavior

	var level_scene = _pick_fight_level(rss)
	_level = level_scene.instantiate() as Level
	_level.ready_to_fight_wait = 0.0
	_level.initialize(rss.gameplay_characters, rss.unlocked_skills)
	add_child(_level)
	
	# Hook signals
	var vl := Component.get_victory_loss_condition_component_or_die(_level) as VictoryLossConditionComponent
	vl.level_finished.connect(_on_level_finished)
	vl.level_failed.connect(_on_level_failed)

	for actor in _level.characters.get_children():
		_enable_logging(actor)
	for actor in _level.towers.get_children():
		_enable_logging(actor)

	_append_log("=== Simulating Stage %d: %s ===" % [rss.current_stage, level_scene.resource_path.get_file().get_basename()])
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
	if _elapsed >= 60.0:
		_finish()
		return
	if _level and is_instance_valid(_level) and (_level.state.is_state(_level.SUMMARY) or _level.state.is_state(_level.DONE)):
		_finish()

func _on_level_finished(_v: int) -> void:
	_outcome = "victory"

func _on_level_failed(_l: int) -> void:
	_outcome = "loss"

func _finish() -> void:
	if _finished:
		return
	_finished = true
	if _level.state.is_state(_level.COMBAT):
		_level.stop()

	_append_log("Outcome: %s in %.1fs" % [_outcome, _elapsed])
	
	if _outcome == "victory":
		var rss := load(_save_path) as RunSaveState
		
		# Unpack and apply end-of-level updates to character stats (repack)
		for i in _level.characters.get_child_count():
			var character = _level.characters.get_child(i)
			var gc = rss.gameplay_characters[i]
			var vitals = character.get_component_or_die(VitalsComponent) as VitalsComponent
			
			var max_hp = gc.attributes.health
			var recovery_amount = int(round(max_hp * gc.attributes.recovery))
			var final_hp = vitals.get_vital_current(VitalsComponent.VitalType.HEALTH)
			if final_hp > 0:
				final_hp = min(final_hp + recovery_amount, max_hp)
			gc.health = final_hp
			
			var effect_actuator = Component.get_or_null(character, EffectActuatorComponent.component) as EffectActuatorComponent
			if effect_actuator:
				gc.relic_state = effect_actuator.extract_relic_state()
				
			# Grant level XP
			gc.grant_xp(_level.granted_xp())
			_append_log("  %s HP remaining: %d/%d, XP: %d" % [gc.name, gc.health, max_hp, gc.xp])
		
		rss.current_phase = RunSaveState.Phase.REWARD
		var err = ResourceSaver.save(rss, _save_path)
		if err != OK:
			_fail("Failed to save post-fight state to %s" % _save_path)
			return

		var stage_rewards: StageRewards = rss.reward_schedule[rss.current_stage - 1]
		_append_log("Next: Reward Stage. Claim rewards on Path 0 or Path 1:")
		for path_idx in range(stage_rewards.sets.size()):
			var rset = stage_rewards.sets[path_idx]
			var names: Array[String] = []
			for reward in rset.rewards:
				if reward is RelicRewardDef:
					names.append("Relic (%s)" % reward.rolled_relic)
				elif reward is TrainerRewardDef:
					names.append("Trainer")
				elif reward is RestRewardDef:
					names.append("Rest")
			_append_log("  Path %d: %s" % [path_idx, ", ".join(names)])

		scene_tree.quit(0)
	else:
		_append_log("Defeat! You can retry the fight by adjusting rules and calling play_level again.")
		scene_tree.quit(1)

func _run_claim_reward(path_idx: int, relic_recipient: String, train_str: String, save_path: String) -> void:
	if not FileAccess.file_exists(save_path):
		_fail("Save file not found at %s" % save_path)
		return
	var rss := load(save_path) as RunSaveState
	if not rss:
		_fail("Failed to load RunSaveState from %s" % save_path)
		return

	if rss.current_phase != RunSaveState.Phase.REWARD:
		_fail("Current phase is FIGHT. Please win the battle first.")
		return

	if path_idx != 0 and path_idx != 1:
		_fail("Invalid or missing --path_idx=<0|1>")
		return

	var stage_rewards: StageRewards = rss.reward_schedule[rss.current_stage - 1]
	rss.reward_path_chosen = path_idx
	var rset = stage_rewards.sets[path_idx]

	for reward in rset.rewards:
		if reward is RestRewardDef:
			for gc in rss.gameplay_characters:
				var max_hp = gc.attributes.health
				var heal_amount = int(round(max_hp * reward.heal_fraction))
				var prev = gc.health
				gc.health = min(prev + heal_amount, max_hp)
				_append_log("Rest applied: %s healed %d -> %d" % [gc.name, prev, gc.health])
		elif reward is RelicRewardDef:
			if relic_recipient.is_empty():
				_fail("Path contains Relic reward. Please specify --relic_recipient=<name>")
				return
			var recipient = _find_character_by_name(rss, relic_recipient)
			if not recipient:
				_fail("Character '%s' not found in party." % relic_recipient)
				return
			recipient.add_relic(reward.rolled_relic)
			_append_log("Relic granted: %s received %s" % [recipient.name, reward.rolled_relic])
		elif reward is TrainerRewardDef:
			if not train_str.is_empty():
				var trainings = train_str.split(",")
				for tr in trainings:
					var parts = tr.split(":")
					if parts.size() != 2:
						_fail("Invalid training format '%s'. Use --train=character:skill" % tr)
						return
					var char_name = parts[0].strip_edges()
					var skill_basename = parts[1].strip_edges()
					var gc = _find_character_by_name(rss, char_name)
					if not gc:
						_fail("Character '%s' not found in party" % char_name)
						return
					var skill_name = _resolve_skill_basename(skill_basename)
					if skill_name == &"":
						_fail("Unknown skill basename: %s" % skill_basename)
						return
					var skill = SkillManager.lookup_skill(skill_name)
					if not skill:
						_fail("Skill lookup failed for: %s" % skill_name)
						return
					if not gc.has_xp(150):
						_fail("Character %s does not have enough XP (150 required, has %d)" % [gc.name, gc.xp])
						return
					gc.use_xp(150)
					gc.acquired_skills.mark_available(skill)
					_append_log("Trainer applied: %s trained %s (remaining XP: %d)" % [gc.name, skill_basename, gc.xp])

	# Reset map phase variables and increment stage
	rss.reward_path_chosen = -1
	rss.reward_nodes_claimed.clear()
	rss.current_stage += 1
	rss.current_phase = RunSaveState.Phase.FIGHT

	if not main_levels_provider.has_levels_at_difficulty(rss.current_stage):
		_append_log("Campaign completed successfully! All stages cleared!")
		scene_tree.quit(0)
		return

	var level_scene = _pick_fight_level(rss)
	_append_log("Stage rewards claimed. Proceeding to next stage.")
	_append_log("Next Stage: %d, Level: %s" % [rss.current_stage, level_scene.resource_path.get_file().get_basename()])
	
	var err = ResourceSaver.save(rss, save_path)
	if err != OK:
		_fail("Failed to save next-stage state to %s" % save_path)
		return
	scene_tree.quit(0)

# --- Helpers ---

func _character_path_for(name: String) -> String:
	match name.to_lower():
		"cleric", "puffin":
			return "res://character/playable_characters/puffin_the_cleric.tres"
		"warrior", "knight", "godric":
			return "res://character/playable_characters/godric_the_knight.tres"
		"rogue", "larian":
			return "res://character/playable_characters/larian_the_rogue.tres"
		"wizard", "bernie":
			return "res://character/playable_characters/bernie_the_wizard.tres"
	return ""

func _find_character_by_name(rss: RunSaveState, name: String) -> GameplayCharacter:
	for gc in rss.gameplay_characters:
		# Check either gc.name or name suffix
		if gc.name.to_lower().contains(name.to_lower()):
			return gc
	return null

func _pick_fight_level(rss: RunSaveState) -> PackedScene:
	var pool := rss.level_provider.levels_at_difficulty(rss.current_stage)
	if pool.is_empty():
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:fight" % [rss.seed, rss.current_stage])
	return pool[rng.randi() % pool.size()]

func _resolve_skill_basename(basename: String) -> StringName:
	for dir in SKILL_TREE_DIRS:
		var path := "%s/%s.tres" % [dir, basename]
		if ResourceLoader.exists(path):
			var skill := load(path) as Skill
			if skill:
				return skill.skill_name
	return &""

# --- Behavior JSON Loader (Duplicated from sim_runner.gd for self-containment) ---

func _load_behavior_cfg(behavior_cfg: Variant) -> StoredBehavior:
	var t := typeof(behavior_cfg)
	if t == TYPE_NIL or (t == TYPE_STRING and behavior_cfg == ""):
		return StoredBehavior.new()
	if t == TYPE_STRING:
		return _load_behavior_json(behavior_cfg)
	if t == TYPE_DICTIONARY:
		return _build_behavior_from_dict(behavior_cfg, "inline")
	_fail("behavior must be a path string or an inline dict, got %s" % type_string(t))
	return null

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
	var fallback_name := path.get_file().get_basename()
	return _build_behavior_from_dict(parsed, fallback_name, path)

func _build_behavior_from_dict(parsed: Dictionary, fallback_name: String, source: String = "inline") -> StoredBehavior:
	var rules_cfg: Array = parsed.get("rules", [])
	var behavior := StoredBehavior.new()
	behavior.name = parsed.get("name", fallback_name)
	for i in rules_cfg.size():
		var rule := _build_rule(rules_cfg[i], i, source)
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
	var sort_cfg = cfg.get("sort")
	if sort_cfg != null:
		var sort_skill := _resolve_skill_object(sort_cfg, Skill.SkillType.TARGET_SORT, "sort", idx, path)
		if not sort_skill:
			return null
		target_sps.params.sort = StoredSkill.from_skill(sort_skill)
	var conditions_arr: Array[StoredParamSkill] = []
	var conds_cfg = cfg.get("conditions")
	if conds_cfg != null:
		if typeof(conds_cfg) != TYPE_ARRAY:
			_fail("%s rule #%d.conditions must be an array" % [path, idx])
			return null
		for ci in conds_cfg.size():
			var c := _build_stored_param_skill(conds_cfg[ci], Skill.SkillType.CONDITION, "conditions[%d]" % ci, idx, path)
			if not c:
				return null
			conditions_arr.append(c)
	elif cfg.has("condition") and cfg.get("condition") != null:
		var c := _build_stored_param_skill(cfg.get("condition"), Skill.SkillType.CONDITION, "condition", idx, path)
		if not c:
			return null
		conditions_arr.append(c)
	return RuleDef.make_with_conditions(target_sps, action_sps, conditions_arr)

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
					_fail("%s rule #%d.%s: unknown cmp '%s'" % [path, rule_idx, field, v])
					return false
				params.cmp = CMP_MAP[v]
			"int_value":
				params.int_value = IntValue.make(int(v))
			"float_value":
				params.float_value = FloatValue.make(float(v))
			"sort":
				var sort_skill := _resolve_skill_object(v, Skill.SkillType.TARGET_SORT, "params.sort", rule_idx, path)
				if not sort_skill:
					return false
				params.sort = StoredSkill.from_skill(sort_skill)
	return true

func _fail(msg: String) -> void:
	push_error(msg)
	if scene_tree:
		scene_tree.quit(1)

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

func _append_log(msg: String, overwrite: bool = false) -> void:
	print(msg)
	var log_path = _save_path.get_basename() + "_log.txt"
	var content := ""
	if not overwrite and FileAccess.file_exists(log_path):
		var f := FileAccess.open(log_path, FileAccess.READ)
		if f:
			content = f.get_as_text()
			f.close()
	content += msg + "\n"
	var f := FileAccess.open(log_path, FileAccess.WRITE)
	if f:
		f.store_string(content)
		f.close()
