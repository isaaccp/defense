extends Screen

# @export var matchmaker_player_count_control := $PanelContainer/VBoxContainer/MatchPanel/...
# @export var join_match_id_control := $PanelContainer/VBoxContainer/JoinPanel/LineEdit
@export var match_button: Button

func _ready() -> void:
	match_button.pressed.connect(self._on_match_button_pressed.bind(OnlineMatch.MatchMode.MATCHMAKER))
	# $PanelContainer/VBoxContainer/CreatePanel/CreateButton.connect("pressed", self, "_on_match_button_pressed", [OnlineMatch.MatchMode.CREATE])
	# $PanelContainer/VBoxContainer/JoinPanel/JoinButton.connect("pressed", self, "_on_match_button_pressed", [OnlineMatch.MatchMode.JOIN])

	OnlineMatch.matchmaker_matched.connect(self._on_OnlineMatch_matchmaker_matched)
	OnlineMatch.match_created.connect(self._on_OnlineMatch_created)
	OnlineMatch.match_joined.connect(self._on_OnlineMatch_joined)

func _on_show(_info: Dictionary = {}) -> void:
	match_button.disabled = false
	# TODO: Just for faster dev, remove later.
	if _info.fallback:
		Online.nakama_scheme = Nakama.DEFAULT_CLIENT_SCHEME
		Online.nakama_host = Nakama.DEFAULT_HOST
		Online.nakama_port = Nakama.DEFAULT_PORT
	else:
		Online.nakama_scheme = 'https'
		Online.nakama_host = 'match.baptr.dev'
		Online.nakama_port = 443

	_on_match_button_pressed.call_deferred(OnlineMatch.MatchMode.MATCHMAKER)

	# matchmaker_player_count_control.value = 2
	# join_match_id_control.text = ''

func _connect_session() -> void:
	ui_layer.show_message("Connecting ...")
	# Get the System's unique device identifier
	var device_id: String
	if OS.has_feature("web"):
		device_id = "aaaaaa%d" % (Time.get_ticks_msec() % 10000)
	else:
		device_id = OS.get_unique_id()

	# Authenticate with the Nakama server using Device Authentication
	var session : NakamaSession = await Online.nakama_client.authenticate_device_async(device_id)
	if session.is_exception():
		ui_layer.show_message("Connection failed: %s" % session)
		print("An error occurred: %s" % session)
		return
	ui_layer.hide_screen()
	ui_layer.show_message("Successfully authenticated")
	Online.nakama_session = session

func _on_match_button_pressed(mode) -> void:
	match_button.disabled = true
	# If our session has expired, show the ConnectionScreen again.
	if Online.nakama_session == null or Online.nakama_session.is_expired():
		_connect_session()
		# Wait to see if we get a new valid session.
		await Online.session_changed
		if Online.nakama_session == null:
			match_button.disabled = false
			return

	# Connect socket to realtime Nakama API if not connected.
	if not Online.is_nakama_socket_connected():
		Online.connect_nakama_socket()
		await Online.socket_connected

	# Call internal method to do actual work.
	match mode:
		OnlineMatch.MatchMode.MATCHMAKER:
			_start_matchmaking()
		OnlineMatch.MatchMode.CREATE:
			_create_match()
		OnlineMatch.MatchMode.JOIN:
			_join_match()

func _start_matchmaking() -> void:
	# var min_players = matchmaker_player_count_control.value
	var min_players = 2

	ui_layer.hide_screen()
	ui_layer.show_message("Looking for match...")

	var data = {
		min_count = min_players,
		string_properties = {
			game = "defense",
			engine = "godot",
		},
		query = "+properties.game:defense +properties.engine:godot",
	}

	OnlineMatch.start_matchmaking(Online.nakama_socket, data)

func _on_OnlineMatch_matchmaker_matched(_players: Dictionary):
	ui_layer.show_screen(ui_layer.ready_screen, { players = _players })

func _create_match() -> void:
	OnlineMatch.create_match(Online.nakama_socket)

func _on_OnlineMatch_created(match_id: String):
	ui_layer.show_screen(ui_layer.ready_screen, { match_id = match_id, clear = true })

func _join_match() -> void:
	# var match_id = join_match_id_control.text.strip_edges()
	#if match_id == '':
	#	ui_layer.show_message("Need to paste Match ID to join")
	#	return
	#if not match_id.ends_with('.'):
	#	match_id += '.'
	#OnlineMatch.join_match(Online.nakama_socket, match_id)
	pass

func _on_OnlineMatch_joined(match_id: String):
	ui_layer.show_screen(ui_layer.ready_screen, { match_id = match_id, clear = true })

#func _on_PasteButton_pressed() -> void:
#	join_match_id_control.text = OS.clipboard

#func _on_LeaderboardButton_pressed() -> void:
#	ui_layer.show_screen("LeaderboardScreen")
