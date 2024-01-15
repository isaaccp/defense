extends UILayerBase

class_name GameplayUILayer

@export_group("Internal")
@export var character_selection_screen: CharacterSelectionScreen
@export var hud: Hud
var overlay: Node

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

func _ready():
	super()
	overlay = %Overlay
	%GameplayMenu.enable(false)

func initialize_state_machine_stack(sm: StateMachine):
	state_machine_stack = StateMachineStack.new(sm)
	%GameplayMenu.initialize(state_machine_stack)

func show_gameplay_menu_screen(existing_run: bool):
	show()
	hud.hide()
	show_screen(%GameplayMenuScreen, {"existing_run": existing_run})

func hide_gameplay_menu_screen():
	hide_screen()

func start_character_selection(level_provider: LevelProvider):
	show()
	hud.hide()
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

func _on_hud_view_log_requested(logging_component):
	show_log_viewer(logging_component)

func show_log_viewer(logging_component: LoggingComponent):
	%LogViewer.show_log(logging_component)

func hide_log_viewer():
	%LogViewer.reset()
	%LogViewer.hide()

func _on_hud_upgrade_window_requested(character):
	show_upgrade_window(character)

func show_upgrade_window(character: Character):
	show_screen(%UpgradeCharacterScreen)
	%UpgradeCharacterScreen.show_upgrades(character)
	hud.hide()

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
