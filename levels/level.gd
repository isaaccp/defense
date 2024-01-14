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

# Not constants so tests can speed them up.
var ready_to_fight_wait = 1.0
var level_end_wait = 3.0
var level_failed_wait = 1.0

var is_paused = false

# Only for F6.
var gameplay: Node

signal level_finished
signal level_failed

signal level_pause_requested
signal level_resume_requested

func _ready():
	# Only when launched with F6.
	if get_parent() == get_tree().root:
		_standalone_ready.call_deferred()

func _standalone_ready():
	# Immediately remove self, we'll test with a copy. Keep parent ref.
	var parent = get_parent()
	get_parent().remove_child(self)

	var level_provider = LevelProvider.new()
	level_provider.levels.append(load(scene_file_path))

	prepare_test_gameplay_characters()

	gameplay = load("res://gameplay.tscn").instantiate()
	parent.add_child(gameplay)
	gameplay.characters = test_gameplay_characters
	gameplay.level_provider = level_provider
	gameplay.ui_layer.show()
	gameplay.ui_layer.hud.show()
	gameplay.play_next_level()

func prepare_test_gameplay_characters():
	var num_players = players if players != -1 else starting_positions.get_child_count()
	# If setting test characters, must set them all.
	assert(test_gameplay_characters.size() in [0, num_players])
	# Same for behaviors (independently from above).
	assert(test_behaviors.size() in [0, num_players])
	if not test_gameplay_characters:
		var gcs: Array[GameplayCharacter] = []
		for i in range(num_players):
			var gc = load("res://character/playable_characters/godric_the_knight.tres")
			gcs.append(gc)
		test_gameplay_characters = gcs
	if test_behaviors:
		for i in range(test_gameplay_characters.size()):
			test_gameplay_characters[i].behavior = test_behaviors[i]
	else:
		for i in range(test_gameplay_characters.size()):
			test_gameplay_characters[i].behavior = StoredBehavior.new()

func initialize(ui_layer: GameplayUILayer, gameplay_characters: Array[GameplayCharacter]):
	self.ui_layer = ui_layer
	for i in gameplay_characters.size():
		if skill_tree_state_add:
			gameplay_characters[i].skill_tree_state.add(skill_tree_state_add)
		if skill_tree_state_override:
			gameplay_characters[i].skill_tree_state = skill_tree_state_override
		var character = gameplay_characters[i].make_character_body()
		character.actor_name = gameplay_characters[i].name
		character.name = character.actor_name
		character.idx = i
		character.peer_id = gameplay_characters[i].peer_id
		character.position = starting_positions.get_child(i).position
		characters.add_child(character)
	var victory = Component.get_victory_loss_condition_component_or_die(self)
	victory.level_failed.connect(_on_level_failed)
	victory.level_finished.connect(_on_level_finished)
	# TODO: Wrap this up inside ui_layer.prepare_level() or similar.
	ui_layer.show()
	ui_layer.hud.show()
	ui_layer.hud.show_play_controls(false)
	ui_layer.hud.set_victory_loss(victory)
	ui_layer.hud.set_characters(characters)
	ui_layer.hud.set_towers(towers)
	ui_layer.hud.start_character_setup(_on_all_ready)
	ui_layer.hud.show_main_message("Prepare", 2.0)
	ui_layer.play_controls_play_pressed.connect(_on_play_pressed)
	ui_layer.play_controls_pause_pressed.connect(_on_pause_pressed)

func _on_all_ready():
	# TODO: Wrap this up inside ui_layer.start_level() or similar.
	ui_layer.hud.show_character_buttons(false)
	ui_layer.hud.show_victory_loss_text(false)
	ui_layer.hud.show_main_message("Fight!", ready_to_fight_wait)
	await get_tree().create_timer(ready_to_fight_wait).timeout
	ui_layer.hud.show_play_controls()
	start()

func _on_level_failed(loss_type: VictoryLossConditionComponent.LossType):
	_on_level_end(false)

func _on_level_finished(victory_type: VictoryLossConditionComponent.VictoryType):
	_on_level_end(true)

func _on_level_end(win: bool):
	# TODO: Maybe later have a way to inspect level, e.g. see
	# health of enemies, inspect logs, etc before moving on.
	ui_layer.hud.show_victory_loss_text(true)
	ui_layer.hud.show_play_controls(false)
	if win:
		await ui_layer.hud.show_main_message("Victory!", level_end_wait)
	else:
		await ui_layer.hud.show_main_message("Failed!", level_failed_wait)
	ui_layer.hud.show_victory_loss(false)
	ui_layer.hud.show_end_level_confirmation(true, win)
	await ui_layer.hud.end_level_confirmed
	ui_layer.hide_log_viewer()
	if win:
		level_finished.emit()
	else:
		level_failed.emit()

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
	victory_loss.level_started()
	_run()

func _run():
	_run_nodes(characters.get_children())
	_run_nodes(enemies.get_children())
	_run_nodes(towers.get_children())
	_run_nodes(spawners.get_children())

func _run_nodes(nodes: Array):
	for node in nodes:
		node.run()
