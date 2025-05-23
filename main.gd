extends Node2D

class_name Main

const gameplay_scene = preload("res://gameplay.tscn")

var ui_layer: UILayer

var players_ready := {}
var game_mode: GameMode

func _ready():
	ui_layer = %UILayer
	# TODO: Just to make it faster for dev, remove later.
	# _on_title_screen_connect_selected.call_deferred()
	pass

func _on_title_screen_game_mode_selected(mode: GameMode):
	game_mode = mode
	if mode.is_local():
		start_gameplay()
	else:
		ui_layer.show_screen(ui_layer.match_screen, {'fallback': game_mode.fallback_local_nakama})

func _on_ready_screen_ready_pressed():
	player_ready.rpc(OnlineMatch.get_my_session_id())

@rpc("any_peer", "call_local")
func player_ready(session_id: String) -> void:
	ui_layer.ready_screen.set_status(session_id, "READY!")

	if multiplayer.is_server() and not players_ready.has(session_id):
		players_ready[session_id] = true
		if players_ready.size() == OnlineMatch.players.size():
			if OnlineMatch.match_state != OnlineMatch.MatchState.PLAYING:
				OnlineMatch.start_playing()
			start_gameplay.rpc()

func load_save_state() -> SaveState:
	var save_state: SaveState
	if FileAccess.file_exists("user://defense_save.tres"):
		save_state = load("user://defense_save.tres")
	else:
		save_state = SaveState.make_new()
		# When starting a new game, unlock all the skills initially available
		# to any playable character.
		for gc in game_mode.level_provider.available_characters:
			for skill_name in gc.acquired_skills.skills:
				var skill = SkillManager.lookup_skill(skill_name)
				if not save_state.unlocked_skills.available(skill):
					save_state.unlocked_skills.mark_available(skill)
	return save_state

@rpc("authority", "call_local")
func start_gameplay():
	ui_layer.hide_screen()
	ui_layer.hide()
	print("Start game")
	var gameplay = gameplay_scene.instantiate() as Gameplay
	var save_state = load_save_state()
	gameplay.initialize(game_mode, save_state)
	gameplay.save_requested.connect(_on_save_requested)
	gameplay.save_and_quit_requested.connect(_on_save_and_quit_requested)
	add_child(gameplay)

func _on_save_requested(save_state: SaveState):
	ResourceSaver.save(save_state, "user://defense_save.tres")

func _on_save_and_quit_requested(save_state: SaveState):
	ResourceSaver.save(save_state, "user://defense_save.tres")
	get_tree().quit()
