extends Node2D

class_name Main

@export_group("Internal")
@export var ui_layer: UILayer
@export var gameplay: Gameplay

var players_ready := {}
var character_selections = {}
var game_over = false
var game_mode: GameMode

func _ready():
	# TODO: Just to make it faster for dev, remove later.
	# _on_title_screen_connect_selected.call_deferred()
	pass

func _on_title_screen_game_mode_selected(mode: GameMode, fallback: bool):
	game_mode = mode
	if mode.is_local():
		start_gameplay()
	else:
		ui_layer.show_screen(ui_layer.match_screen, {'fallback': fallback})		

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

@rpc("authority", "call_local")
func start_gameplay():
	ui_layer.hide_screen()
	ui_layer.hide()
	print("Start game")
	gameplay.start(game_mode)
