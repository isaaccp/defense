extends GutTest

const gameplay_scene = preload("res://gameplay.tscn")
const test_game_mode = preload("res://tests/gameplay/test_game_mode.tres")

var game_mode: GameMode
var gameplay: Gameplay
var expected_characters: int

# Consider mocking fully instead?
func double_level_provider(level_provider: LevelProvider):
	var d = partial_double(LevelProvider).new()
	d.set_from(level_provider)
	return d

func before_all():
	expected_characters = test_game_mode.level_provider.players

func before_each():
	# If we don't create a copy, level_provider would be shared
	# across tests.
	game_mode = test_game_mode.duplicate(true)
	game_mode.level_provider = double_level_provider(game_mode.level_provider)
	gameplay = gameplay_scene.instantiate()
	gameplay.ready_to_fight_wait = 0.2
	gameplay.level_end_wait = 0.2
	add_child_autoqfree(gameplay)
	gameplay.start(game_mode)

func mark_characters_ready(hud: Hud):
	for i in range(hud.character_view_count()):
		hud.character_view(i).readiness_updated.emit(true)

func test_end_to_end():
	var ui_layer = gameplay.ui_layer
	var hud = ui_layer.hud

	gut.p("Start")
	await wait_frames(1, "Waiting for character selection screen load")
	var selection_screen = ui_layer.character_selection_screen
	assert_true(selection_screen.visible)
	assert_eq(expected_characters, selection_screen.character_selector_count())
	assert_eq(expected_characters, selection_screen.selections_wanted)
	assert_null(gameplay.level)
	assert_call_count(game_mode.level_provider, "next_level", 0)

	gut.p("Character Selection Screen")
	for i in range(expected_characters):
		selection_screen.character_selector(i).character_selected.emit(Enum.CharacterId.KNIGHT)
	await wait_frames(1, "Waiting for level load")
	assert_not_null(gameplay.level)
	assert_true(gameplay.level.is_frozen)
	assert_eq(hud.character_view_count(), expected_characters)
	assert_call_count(game_mode.level_provider, "next_level", 1)

	gut.p("Marking characters ready for level to start")
	mark_characters_ready(hud)
	await wait_for_signal(gameplay.level_started, gameplay.ready_to_fight_wait + 0.5, "Waiting for level to start")
	assert_signal_emitted(gameplay, "level_started")
	assert_false(gameplay.level.is_frozen)

	gut.p("Level has started")
	var victory = Component.get_victory_loss_condition_component_or_die(gameplay.level)
	# Instant win scenario has a timed victory, wait for it.
	await wait_for_signal(victory.level_finished, victory.time + 0.25, "Waiting for victory")

	gut.p("Level has finished")
	await wait_seconds(gameplay.level_end_wait + 0.1, "Waiting for level end wait to be over")

	hud.end_level_confirmed.emit()

	await wait_frames(5)

	gut.p("Loading next level")
	assert_call_count(game_mode.level_provider, "next_level", 2)

	# TODO: Test failure condition.
	# TODO: Test end game.
