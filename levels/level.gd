extends Actor

class_name Level

@export_group("Metadata")
# Relative difficulty band, used by the map system to slot levels into nodes
# of comparable challenge.
@export var difficulty: int = 1

@export_group("Tutorial")
# To be used for e.g. tutorial levels in which we may
# want a particular set of skills acquired.
# Replaces skill tree state.
@export var acquired_skills_override: SkillTreeState
# Same as above, but it only adds to existing tree, so
# it's less work if you don't need to remove skills.
@export var acquired_skills_override_add: SkillTreeState
# Same for unlocked_skills.
# TODO: Actually use those, should be done from outside,
# or pass unlocked_skills to level if needed.
@export var unlocked_skills_override: SkillTreeState
@export var unlocked_skills_override_add: SkillTreeState

@export_group("Testing")
# For testing long level flows, instantly wins level.
@export var instant_win = false
# Only used when running through F6. By default we
# create as many players as starting positions in the
# level, but that's at least 2 as the base level has 2
# and it'd be a pain to change that, so override it here
# as needed.
@export var players = -1
# Used when playing the scene directly.
@export var test_gameplay_characters: Array[GameplayCharacter]
# Provide those separately so you can e.g. load the default
# characters but provide modified behaviors without altering
# their scenes.
@export var test_behaviors: Array[StoredBehavior]

var source_gameplay_characters: Array[GameplayCharacter]

@export_group("Internal")
@export var characters: Node2D
@export var enemies: Node2D
@export var towers: Node2D
@export var spawners: Node2D
@export var interactables: Node2D
@export var starting_positions: Node
@export var placement_component: PlacementComponent
var selected_relics: Array[RelicDef]

signal prepare_started(characters: Node2D, towers: Node2D, selected_relics: Array[RelicDef], victory: Node)
signal prepare_exited()
signal combat_started(ready_to_fight_wait: float)
signal combat_exited()
signal summary_started(win: bool, characters: Node2D, xp_text: String)
signal enemy_selected(enemy: Enemy)

var state = StateMachine.new(Constants.LevelStateMachineName)
var PREPARE = state.add("prepare")
var COMBAT = state.add("combat")
var SUMMARY = state.add("summary")
var DONE = state.add("done", true)

var win: bool
var is_paused = false

# Pick radius (px) used to grab a character for drag-placement during PREPARE.
const _drag_pick_radius := 20.0
var _dragging_character: Character = null
var _drag_offset := Vector2.ZERO

# Not constants so tests can speed them up.
var ready_to_fight_wait = 1.0

signal level_finished
signal level_failed

signal level_pause_requested
signal level_resume_requested

## Aggregated from Chest.gold_earned for every chest in the level.
signal gold_earned(amount: int)

func _ready():
	# Only when launched with F6.
	if get_parent() == get_tree().root:
		_standalone_ready.call_deferred()
	state.connect_signals(self)
	state.change_state.call_deferred(PREPARE)

func _exit_tree():
	pass

func exit():
	# Sometimes level pauses the tree, make sure to unpause.
	# Should be called instead of level.queue_free().
	# This can't be on _exit_tree() because get_tree() checks to
	# make sure it's inside the tree. Weirdly it seems to work,
	# but it causes a warning.
	get_tree().paused = false
	queue_free()

func initialize(gameplay_characters: Array[GameplayCharacter], unlocked_skills: SkillTreeState = null):
	source_gameplay_characters = gameplay_characters
	# Forward each chest's gold reward to the level-level signal so Run
	# (which already connects to level signals) can aggregate onto
	# RunSaveState. Chests are placed under YSorted/Interactables.
	if interactables:
		for child in interactables.get_children():
			var interactable = child as Interactable
			if interactable:
				if not interactable.meets_requirements(unlocked_skills):
					interactable.queue_free()
					continue
			
			var chest := child as Chest
			if chest and not chest.gold_earned.is_connected(_on_chest_gold_earned):
				chest.gold_earned.connect(_on_chest_gold_earned)
	for i in gameplay_characters.size():
		var gc = gameplay_characters[i]
		if acquired_skills_override_add:
			gc.acquired_skills.add(acquired_skills_override_add)
		if acquired_skills_override:
			gc.acquired_skills = acquired_skills_override
		var character = CharacterSceneManager.make(gc)
		# Consider putting all this in initialize.
		character.actor_name = gc.name
		character.idx = i
		character.peer_id = gc.peer_id
		character.position = starting_positions.get_child(i).position
		characters.add_child(character)

func _on_chest_gold_earned(amount: int) -> void:
	gold_earned.emit(amount)

func _on_prepare_entered():
	var victory = Component.get_victory_loss_condition_component_or_die(self)
	victory.level_failed.connect(_on_level_failed)
	victory.level_finished.connect(_on_level_finished)
	if placement_component and _placement_drag_enabled():
		placement_component.set_zones_visible(true)
	prepare_started.emit(characters, towers, selected_relics, victory)

func _on_prepare_exited():
	if placement_component:
		placement_component.set_zones_visible(false)
	_dragging_character = null
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	prepare_exited.emit()

func _on_all_ready():
	state.change_state.call_deferred(COMBAT)

func _on_combat_entered():
	combat_started.emit(ready_to_fight_wait)
	await get_tree().create_timer(ready_to_fight_wait).timeout
	start()

func _on_combat_exited():
	combat_exited.emit()

func _on_summary_entered():
	var xp = XPComponent.get_or_die(self).xp()
	summary_started.emit(win, characters, xp.text if win else "")

func play_combat() -> void:
	_on_play_pressed()

func pause_combat() -> void:
	_on_pause_pressed()

func complete_character_setup() -> void:
	_on_all_ready()

func play_next() -> void:
	_on_play_next_selected()

func try_again() -> void:
	_on_try_again_selected()

func _on_play_next_selected():
	# Save health and relics into persistent state and move on.
	for i in characters.get_child_count():
		var character = characters.get_child(i)
		var gc = source_gameplay_characters[i]
		var vitals_component = character.get_component_or_die(VitalsComponent) as VitalsComponent
		gc.health = vitals_component.get_vital_current(VitalsComponent.VitalType.HEALTH)
		
		var effect_actuator = Component.get_or_null(character, EffectActuatorComponent.component) as EffectActuatorComponent
		if effect_actuator:
			gc.relic_state = effect_actuator.extract_relic_state()
			
	level_finished.emit()
	state.change_state.call_deferred(DONE)

func _on_try_again_selected():
	level_failed.emit()
	state.change_state.call_deferred(DONE)

func _on_summary_exited():
	pass

func _on_done_entered():
	pass

func _on_level_failed(_loss_type: VictoryLossConditionComponent.LossType):
	win = false
	state.change_state.call_deferred(SUMMARY)

func _on_level_finished(_victory_type: VictoryLossConditionComponent.VictoryType):
	win = true
	stop()
	
	# Apply end-of-level natural recovery.
	for i in characters.get_child_count():
		var character = characters.get_child(i)
		var gc = source_gameplay_characters[i]
		var vitals = character.get_component_or_die(VitalsComponent) as VitalsComponent
		var max_hp = gc.attributes.health
		var recovery_amount = int(round(max_hp * gc.attributes.recovery))
		if recovery_amount > 0:
			var actual_update = vitals.apply_vital_change(VitalsComponent.VitalType.HEALTH, recovery_amount, false)
			if actual_update and actual_update.current_value > actual_update.prev_value:
				var actual_healed = actual_update.current_value - actual_update.prev_value
				var log_comp = Component.get_or_null(character, LoggingComponent.component) as LoggingComponent
				if log_comp and log_comp.track_stats:
					log_comp.stats.add_stat(Stat.make(Stat.NaturalRecovery, actual_healed))
					
	state.change_state.call_deferred(SUMMARY)

func granted_xp() -> int:
	var xp = XPComponent.get_or_die(self).xp()
	return xp.amount if xp else 0

func get_aggregate_stats() -> AggregateStats:
	var aggregate = AggregateStats.new()
	for child in characters.get_children():
		var log_comp = Component.get_or_null(child, LoggingComponent.component) as LoggingComponent
		if log_comp:
			var char_comp = child as Character
			var gc = source_gameplay_characters[char_comp.idx]
			for stat_name in log_comp.stats.stats:
				aggregate.add_stat(Stat.make(stat_name, log_comp.stats.stats[stat_name]), gc.scene_id)
				
	for child in towers.get_children():
		var log_comp = Component.get_or_null(child, LoggingComponent.component) as LoggingComponent
		if log_comp:
			for stat_name in log_comp.stats.stats:
				aggregate.add_tower_stat(Stat.make(stat_name, log_comp.stats.stats[stat_name]))
				
	for child in enemies.get_children():
		var log_comp = Component.get_or_null(child, LoggingComponent.component) as LoggingComponent
		if log_comp:
			for stat_name in log_comp.stats.stats:
				aggregate.add_stat(Stat.make(stat_name, log_comp.stats.stats[stat_name]))

	return aggregate

func _on_play_pressed():
	is_paused = false
	get_tree().paused = false

func _on_pause_pressed():
	is_paused = true
	get_tree().paused = true

func paused() -> bool:
	return is_paused

# Placement drag is local-only for now; online matches keep StartingPositions.
func _placement_drag_enabled() -> bool:
	return OnlineMatch.match_mode == OnlineMatch.MatchMode.NONE

func _unhandled_input(event: InputEvent):
	if not state.is_state(PREPARE):
		return
	if not placement_component or not _placement_drag_enabled():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var world := get_global_mouse_position()
		if event.pressed:
			_dragging_character = _character_at(world)
			if _dragging_character:
				_drag_offset = _dragging_character.position - world
		else:
			_dragging_character = null
			_update_hover_cursor(world)
	elif event is InputEventMouseMotion:
		var world := get_global_mouse_position()
		if _dragging_character:
			_dragging_character.position = placement_component.closest_valid_point(world + _drag_offset)
		else:
			_update_hover_cursor(world)

func _update_hover_cursor(world_point: Vector2) -> void:
	var shape := Input.CURSOR_MOVE if _character_at(world_point) else Input.CURSOR_ARROW
	Input.set_default_cursor_shape(shape)

func _character_at(world_point: Vector2) -> Character:
	var r2 := _drag_pick_radius * _drag_pick_radius
	for child in characters.get_children():
		var c := child as Character
		if c and c.position.distance_squared_to(world_point) <= r2:
			return c
	return null

func start():
	var victory_loss = Component.get_victory_loss_condition_component_or_die(self)
	if instant_win:
		victory_loss.victory.append(VictoryLossConditionComponent.VictoryType.TIME)
		victory_loss.time = 0.1

	# Connect spawners so we can track enemies to make them pickable.
	for spawner in spawners.get_children():
		spawner.enemy_spawned.connect(_on_enemy_spawned)

	# Wire up shared focus to characters
	if towers.get_child_count() > 0:
		var tower = towers.get_child(0)
		var tower_vitals = Component.get_or_null(tower, VitalsComponent.component) as VitalsComponent
		if tower_vitals:
			for child in characters.get_children():
				var vitals = Component.get_or_null(child, VitalsComponent.component) as VitalsComponent
				if vitals:
					vitals.shared_focus_vitals = tower_vitals

	# Runs all components.
	run()
	_run_nodes(characters.get_children())
	_run_nodes(enemies.get_children())
	_run_nodes(towers.get_children())
	_run_nodes(spawners.get_children())

func stop():
	_stop_nodes(characters.get_children())
	_stop_nodes(enemies.get_children())
	_stop_nodes(towers.get_children())
	_stop_nodes(spawners.get_children())

func _run_nodes(nodes: Array):
	for node in nodes:
		node.run()

func _stop_nodes(nodes: Array):
	for node in nodes:
		node.stop()

func _on_enemy_spawned(enemy: Enemy):
	enemy.selected.connect(_on_enemy_selected)

func _on_enemy_selected(enemy: Enemy):
	enemy_selected.emit(enemy)

func _standalone_ready():
	# Immediately remove self, we'll test with a copy. Keep parent ref.
	var parent = get_parent()
	get_parent().remove_child(self)
	_standalone_ready_next_frame.call_deferred(parent)

func _standalone_ready_next_frame(parent: Node):
	var game_mode = GameMode.new() # ignore-dep
	game_mode.level_provider = LevelProvider.new() # ignore-dep
	game_mode.level_provider.levels.append(load(scene_file_path))
	game_mode.dev_behavior_library = load("res://behavior/resources/dev_behavior_library.tres")
	prepare_test_gameplay_characters()

	# No type to prevent pulling in deps.
	var gameplay = load("res://gameplay.tscn").instantiate()
	var save_state = SaveState.make_new() # ignore-dep
	save_state.run_save_state = RunSaveState.make(test_gameplay_characters, game_mode.level_provider, save_state.unlocked_skills, save_state.unlocked_milestones, save_state.milestone_progress) # ignore-dep
	gameplay.initialize(game_mode, save_state)
	parent.add_child(gameplay)
	# initialize() calls deferred to set state to MENU, so need
	# to wait a bit for it.
	await parent.get_tree().create_timer(0.1).timeout
	gameplay.state.change_state(gameplay.RUN)

func prepare_test_gameplay_characters():
	var num_players = players if players != -1 else starting_positions.get_child_count()
	# If setting test characters, must set them all.
	assert(test_gameplay_characters.size() in [0, num_players])
	# Same for behaviors (independently from above).
	assert(test_behaviors.size() in [0, num_players])
	if not test_gameplay_characters:
		var gcs: Array[GameplayCharacter] = []
		for i in range(num_players):
			var gc = load("res://character/playable_characters/godric_the_knight.tres").duplicate(true)
			gc.acquired_skills = SkillTreeState.new()
			gc.acquired_skills.full = true
			gcs.append(gc)
		test_gameplay_characters = gcs
		for gc in test_gameplay_characters:
			# TODO: Just call initialize() when gc has it.
			gc.health = gc.attributes.health
	if test_behaviors:
		for i in range(test_gameplay_characters.size()):
			test_gameplay_characters[i].behavior = test_behaviors[i]
	else:
		for i in range(test_gameplay_characters.size()):
			test_gameplay_characters[i].behavior = StoredBehavior.new()
