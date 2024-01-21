extends Actor

class_name Level

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

@export_group("Internal")
@export var characters: Node2D
@export var enemies: Node2D
@export var towers: Node2D
@export var spawners: Node2D
@export var starting_positions: Node

var ui_layer: GameplayUILayer

const StateMachineName = "level"
var state = StateMachine.new(StateMachineName)
var PREPARE = state.add("prepare")
var COMBAT = state.add("combat")
var SUMMARY = state.add("summary")
var DONE = state.add("done", true)

var win: bool
var is_paused = false

# Not constants so tests can speed them up.
var ready_to_fight_wait = 1.0

signal level_finished
signal level_failed

signal level_pause_requested
signal level_resume_requested

func _ready():
	# Only when launched with F6.
	if get_parent() == get_tree().root:
		_standalone_ready.call_deferred()
	state.connect_signals(self)
	state.change_state.call_deferred(PREPARE)
	if ui_layer:
		ui_layer.state_machine_stack.add_state_machine(state)
		ui_layer.show()
		ui_layer.hud.show()

func _exit_tree():
	if ui_layer:
			ui_layer.state_machine_stack.remove_state_machine(state)
			ui_layer.hud.hide()

func initialize(gameplay_characters: Array[GameplayCharacter], ui_layer: GameplayUILayer = null):
	self.ui_layer = ui_layer
	for i in gameplay_characters.size():
		var gc = gameplay_characters[i]
		if acquired_skills_override_add:
			gc.acquired_skills.add(acquired_skills_override_add)
		if acquired_skills_override:
			gc.acquired_skills = acquired_skills_override
		var character = Character.make(gc)
		# Consider putting all this in initialize.
		character.actor_name = gc.name
		character.idx = i
		character.peer_id = gc.peer_id
		character.position = starting_positions.get_child(i).position
		var attributes_component = AttributesComponent.get_or_die(character)
		attributes_component.base_attributes = gc.attributes
		characters.add_child(character)

func _on_prepare_entered():
	var victory = Component.get_victory_loss_condition_component_or_die(self)
	victory.level_failed.connect(_on_level_failed)
	victory.level_finished.connect(_on_level_finished)
	# TODO: Wrap this up inside ui_layer.prepare_level() or similar.
	if ui_layer:
		ui_layer.hud.show_play_controls(false)
		ui_layer.hud.set_victory_loss(victory)
		ui_layer.hud.set_characters(characters)
		ui_layer.hud.set_towers(towers)
		ui_layer.hud.start_character_setup(_on_all_ready)
		ui_layer.hud.show_main_message("Prepare", 2.0)
		ui_layer.play_controls_play_pressed.connect(_on_play_pressed)
		ui_layer.play_controls_pause_pressed.connect(_on_pause_pressed)

func _on_prepare_exited():
	if ui_layer:
		ui_layer.hud.show_character_buttons(false)
		ui_layer.hud.show_victory_loss_text(false)

func _on_all_ready():
	state.change_state.call_deferred(COMBAT)

func _on_combat_entered():
	if ui_layer:
			ui_layer.hud.show_main_message("Fight!", ready_to_fight_wait)
	await get_tree().create_timer(ready_to_fight_wait).timeout
	if ui_layer:
		ui_layer.hud.show_play_controls()
	start()

func _on_combat_exited():
	if ui_layer:
		ui_layer.hud.show_play_controls(false)

func _on_summary_entered():
	if ui_layer:
		ui_layer.hud.show_victory_loss_text(true)
		ui_layer.hud.show_victory_loss(false)
		ui_layer.hide_log_viewer()
		var xp = XPComponent.get_or_die(self).xp()
		ui_layer.show_level_end(win, characters, xp.text if win else "")
		ui_layer.play_next_selected.connect(_on_play_next_selected)
		ui_layer.try_again_selected.connect(_on_try_again_selected)

func _on_play_next_selected():
	# Save health into persistent state and move on.
	for character in characters.get_children():
		var persistent_state = Component.get_persistent_game_state_component_or_die(character)
		var health_component = HealthComponent.get_or_die(character)
		persistent_state.state.health = health_component.health
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
	state.change_state.call_deferred(SUMMARY)

func granted_xp() -> int:
	var xp = XPComponent.get_or_die(self).xp()
	return xp.amount if xp else 0

func _on_play_pressed():
	is_paused = false
	get_tree().paused = false

func _on_pause_pressed():
	is_paused = true
	get_tree().paused = true

func paused() -> bool:
	return is_paused

func start():
	var victory_loss = Component.get_victory_loss_condition_component_or_die(self)
	if instant_win:
		victory_loss.victory.append(VictoryLossConditionComponent.VictoryType.TIME)
		victory_loss.time = 0.1
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

func _standalone_ready():
	# Immediately remove self, we'll test with a copy. Keep parent ref.
	var parent = get_parent()
	get_parent().remove_child(self)
	_standalone_ready_next_frame.call_deferred(parent)

func _standalone_ready_next_frame(parent: Node):
	var game_mode = GameMode.new()
	game_mode.level_provider = LevelProvider.new()
	game_mode.level_provider.levels.append(load(scene_file_path))
	prepare_test_gameplay_characters()

	# No type to prevent pulling in deps.
	var gameplay = load("res://gameplay.tscn").instantiate()
	var save_state = SaveState.make_new()
	save_state.run_save_state = RunSaveState.make(test_gameplay_characters, game_mode.level_provider)
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
