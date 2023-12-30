extends Screen



var peer_status_scene = preload("res://ui/peer_status.tscn")

@export var ready_button: Button
@export var match_id_container: Container
@export var match_id_line_edit: LineEdit
@export var status_container: Container

signal ready_pressed

func _ready() -> void:
	clear_players()

	OnlineMatch.player_joined.connect(_on_player_joined)
	OnlineMatch.player_left.connect(_on_player_left)
	OnlineMatch.player_status_changed.connect(_on_player_status_changed)
	OnlineMatch.match_ready.connect(_on_match_ready)
	OnlineMatch.match_not_ready.connect(_on_match_not_ready)

func _on_show(info: Dictionary = {}) -> void:
	var players: Dictionary = info.get("players", {})
	var match_id: String = info.get("match_id", '')
	var clear: bool = info.get("clear", false)

	if players.size() > 0 or clear:
		clear_players()

	for session_id in players:
		add_player(session_id, players[session_id]['username'])

	if match_id:
		match_id_container.visible = true
		match_id_line_edit.text = match_id
	else:
		match_id_container.visible = false

	ready_button.grab_focus()

func clear_players() -> void:
	for child in status_container.get_children():
		status_container.remove_child(child)
		child.queue_free()
	ready_button.disabled = true

func hide_match_id() -> void:
	match_id_container.visible = false

func add_player(session_id: String, username: String) -> void:
	if not status_container.has_node(session_id):
		var status = peer_status_scene.instantiate()
		status_container.add_child(status)
		status.initialize(username)
		status.name = session_id

func remove_player(session_id: String) -> void:
	var status = status_container.get_node(session_id)
	if status:
		status.queue_free()

func set_status(session_id: String, status: String) -> void:
	var status_node = status_container.get_node(session_id)
	if status_node:
		status_node.set_status(status)

func get_status(session_id: String) -> String:
	var status_node = status_container.get_node(session_id)
	if status_node:
		return status_node.status
	return ''

func reset_status(status: String) -> void:
	for child in status_container.get_children():
		child.set_status(status)

func set_score(session_id: String, score: int) -> void:
	var status_node = status_container.get_node(session_id)
	if status_node:
		status_node.set_score(score)

func set_ready_button_enabled(enabled: bool = true) -> void:
	ready_button.disabled = !enabled
	if enabled:
		ready_button.grab_focus()
		# TODO: Just for faster dev, remove later.
		_on_ready_button_pressed.call_deferred()

func _on_ready_button_pressed() -> void:
	ready_pressed.emit()

func _on_match_copy_button_pressed() -> void:
	DisplayServer.clipboard_set(match_id_line_edit.text)

func _on_player_joined(player) -> void:
	add_player(player.session_id, player.username)

func _on_player_left(player) -> void:
	remove_player(player.session_id)

func _on_player_status_changed(player, status) -> void:
	if status == OnlineMatch.PlayerStatus.CONNECTED:
		# Don't go backwards from 'READY!'
		if get_status(player.session_id) != 'READY!':
			set_status(player.session_id, 'Connected.')
	elif status == OnlineMatch.PlayerStatus.CONNECTING:
		set_status(player.session_id, 'Connecting...')

func _on_match_ready(_players: Dictionary) -> void:
	set_ready_button_enabled(true)

func _on_match_not_ready() -> void:
	set_ready_button_enabled(false)
