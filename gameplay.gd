extends Node2D

class_name Gameplay

const run_scene = preload("res://run/run.tscn")

@export_group("Internal")
@export var ui_layer: GameplayUILayer

@export_group("Debug")
# TODO: Remove next two, move to run.
@export var level_provider: LevelProvider
var save_state: SaveState

const StateMachineName = "gameplay"
var state = StateMachine.new(StateMachineName)
var MENU = state.add("menu")
var RUN = state.add("run")
# We'll later have an extra state for "between runs" unlocks.

# Current run if we are in RUN state.
var run: Run

signal run_started
signal save_and_quit(save_state: SaveState)

func _ready():
	state.connect_signals(self)
	# TODO: Encapsulate all the hud business better.
	Global.subviewport = %SubViewport
	ui_layer.set_save_state(save_state)
	ui_layer.initialize_state_machine_stack(state)
	ui_layer.hud.set_behavior_library(save_state.behavior_library)
	state.change_state.call_deferred(MENU)

func initialize(game_mode: GameMode, save_state: SaveState):
	self.save_state = save_state
	level_provider = game_mode.level_provider
	if game_mode.is_multiplayer():
		assert(level_provider.players == 2)

func _on_menu_entered():
	ui_layer.show_gameplay_menu_screen(save_state.run_save_state != null)

func _on_menu_exited():
	ui_layer.hide_gameplay_menu_screen()

func _on_run_entered():
	run = run_scene.instantiate() as Run
	run.initialize(save_state.run_save_state, ui_layer)
	run.run_finished.connect(_on_run_finished)
	%RunParent.add_child(run)

func _on_run_exited():
	run.queue_free()
	run = null

func _on_run_finished():
	save_state.run_save_state = null
	state.change_state.call_deferred(MENU)

func _on_gameplay_ui_layer_full_pause_requested():
	get_tree().paused = true

func _on_gameplay_ui_layer_full_resume_requested():
	if state.is_state(RUN) and run.paused():
		return
	get_tree().paused = false

func _on_gameplay_ui_layer_save_and_quit_requested():
	save_and_quit.emit(save_state)

func _on_gameplay_ui_layer_new_run():
	save_state.run_save_state = RunSaveState.make([], level_provider)
	state.change_state.call_deferred(RUN)

func _on_gameplay_ui_layer_continue_run():
	state.change_state.call_deferred(RUN)
