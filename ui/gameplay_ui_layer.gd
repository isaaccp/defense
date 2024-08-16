extends UILayerBase

class_name GameplayUILayer

@export_group("Internal")
@export var character_selection_screen: CharacterSelectionScreen
@export var hud: Hud

var save_state: SaveState

# Keeps track of the stack of states, e.g. gameplay/run/etc, so it
# can be used for UI decisions easily.
var state_machine_stack: StateMachineStack

## New run was selected in gameplay menu screen.
signal new_run
## Continue run was selected in gameplay menu screen.
signal continue_run
## All characters were selected in character selection screen.
signal character_selection_screen_selection_ready(character_selections: Array[int])
## Behavior was modified in the programming UI.
signal behavior_modified(character_idx: int, behavior: StoredBehavior)
## Restarts the level without any changes.
signal restart_requested
## Requests a pause on level. Hud, etc still work.
signal play_controls_play_pressed
## Resumes pause on level.
signal play_controls_pause_pressed
## Discards all changes from level start and restarts the level.
signal reset_requested
## Requests a full pause (regardless of "pause" state in play controls).
signal full_pause_requested
## Requests a resumse from a full pause.
signal full_resume_requested
## Requests save and quit.
signal save_and_quit_requested
## Abandon run requested from menu.
signal abandon_run_requested
## Play next level selected.
signal play_next_selected
## Try level again selected.
signal try_again_selected
## Continue pressed on pre run screen.
signal pre_run_continue_pressed
## Continue pressed on run sumary screen.
signal run_summary_continue_selected
## Continue pressed on between levels screen.
signal between_levels_continue_selected

func _ready():
	super()
	%GameplayMenu.enable(false)
	# Hide all top level items. We want to make sure that we can
	# show/hide them in editor for debugging without causing significant
	# issues.
	for screen in %Screens.get_children():
		screen.hide()
	for overlay in %Overlay.get_children():
		overlay.hide()
	for window in %Windows.get_children():
		window.hide()

func show_screen(screen: Control, info: Dictionary = {}) -> void:
	show()
	%Screens.show()
	super(screen, info)

func set_save_state(save_state: SaveState):
	self.save_state = save_state

func initialize_state_machine_stack(sm: StateMachine):
	state_machine_stack = StateMachineStack.new(sm)
	%GameplayMenu.initialize(state_machine_stack)

func show_gameplay_menu_screen(existing_run: bool):
	show_screen(%GameplayMenuScreen, {"existing_run": existing_run})

func start_character_selection(level_provider: LevelProvider):
	character_selection_screen.set_characters(level_provider.players, level_provider.available_characters)
	show_screen(character_selection_screen)

func end_character_selection():
	character_selection_screen.hide()

func _on_character_selection_screen_selection_ready(character_selections: Array[int]):
	character_selection_screen_selection_ready.emit(character_selections)

func _on_behavior_modified(character_idx: int, behavior: StoredBehavior):
	behavior_modified.emit(character_idx, behavior)

func _on_hud_restart_requested():
	restart_requested.emit()

func _on_hud_view_log_requested(actor: Actor):
	show_log_viewer(actor)

func show_log_viewer(actor: Actor):
	%LogViewer.show_log(actor.actor_name, actor.get_component_or_die(LoggingComponent))

func hide_log_viewer():
	%LogViewer.reset()
	%LogViewer.hide()

func _on_hud_upgrade_window_requested(character):
	show_upgrade_window(character)

func show_upgrade_window(character: Character):
	show_screen(%UpgradeCharacterScreen, {
		"save_state": save_state,
		"character": character,
	})
	hud.hide()

func show_pre_run_screen():
	show_screen(%PreRunScreen, {"save_state": save_state})

func show_run_summary_screen(text: String):
	show_screen(%RunSummaryScreen, {"text": text})

func show_between_levels_screen(text: String):
	show_screen(%BetweenLevelsScreen, {"text": text})

func show_level_end(win: bool, character_node: Node, granted_xp_text: String):
	%LevelEnd.prepare(win, character_node, granted_xp_text)
	%LevelEnd.show()

func hide_level_end():
	%LevelEnd.hide()

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		%GameplayMenu.enable(true)
		full_pause_requested.emit()
		get_viewport().set_input_as_handled()

func _on_hud_play_controls_play_pressed():
	play_controls_play_pressed.emit()

func _on_hud_play_controls_pause_pressed():
	play_controls_pause_pressed.emit()

func _on_gameplay_menu_closed():
	full_resume_requested.emit()

func _on_gameplay_menu_reset_requested():
	reset_requested.emit()

func _on_gameplay_menu_save_and_quit_requested():
	save_and_quit_requested.emit()

func _on_gameplay_menu_screen_new_run():
	new_run.emit()

func _on_gameplay_menu_screen_continue_run():
	continue_run.emit()

func _on_gameplay_menu_abandon_run_requested():
	abandon_run_requested.emit()

func _on_level_end_play_next_selected():
	play_next_selected.emit()

func _on_level_end_try_again_selected():
	try_again_selected.emit()

func _on_pre_run_screen_continue_pressed():
	pre_run_continue_pressed.emit()

func _on_run_summary_screen_continue_selected():
	run_summary_continue_selected.emit()
	hide_screen()

func _on_between_levels_screen_continue_selected():
	between_levels_continue_selected.emit()
	hide_screen()
