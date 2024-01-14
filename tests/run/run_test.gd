extends GutTest

const run_scene = preload("res://run/run.tscn")
const gameplay_ui_layer_scene = preload("res://ui/gameplay_ui_layer.tscn")
const instant_win_level_provider = preload("res://levels/test/test_instant_win_upgrade.tres")

var run: Run
var expected_characters: int
var level_provider: LevelProvider
var ui_layer: GameplayUILayer

# Consider mocking fully instead?
func double_level_provider(level_provider: LevelProvider):
	var d = partial_double(LevelProvider).new()
	d.set_from(level_provider)
	return d

func before_all():
	expected_characters = instant_win_level_provider.players

func before_each():
	ui_layer = gameplay_ui_layer_scene.instantiate()
	# If we don't create a copy, level_provider would be shared
	# across tests.
	level_provider = double_level_provider(instant_win_level_provider)
	run = run_scene.instantiate()
	run.initialize(RunSaveState.make([], level_provider), ui_layer)
	add_child_autoqfree(run)
	add_child_autoqfree(ui_layer)
	await wait_frames(1)

func mark_characters_ready(hud: Hud):
	for i in range(hud.character_view_count()):
		hud.character_view(i).readiness_updated.emit(true)

func test_end_to_end():
	var hud = ui_layer.hud

	gut.p("Start")
	await wait_frames(1, "Waiting for character selection screen load")
	var selection_screen = ui_layer.character_selection_screen
	assert_true(selection_screen.visible)
	assert_eq(expected_characters, selection_screen.character_selector_count())
	assert_eq(expected_characters, selection_screen.selections_wanted)
	assert(run.state.is_state(run.CHARACTER_SELECTION))
	assert_call_count(level_provider, "load_level", 0)

	gut.p("Character Selection Screen")
	var selection: Array[int] = [0, 0]
	ui_layer.character_selection_screen_selection_ready.emit(selection)

	await wait_frames(1, "Waiting for level load")
	assert(run.state.is_state(run.WITHIN_LEVEL))
	assert_not_null(run.level)
	assert_eq(hud.character_view_count(), expected_characters)
	assert_call_count(level_provider, "load_level", 1)

	run.level.level_finished.emit()
	await wait_frames(5)

	gut.p("Loading next level")
	assert_call_count(level_provider, "advance", 1)
	assert_call_count(level_provider, "load_level", 2)

	# TODO: Test failure condition.
	# TODO: Test end game.
