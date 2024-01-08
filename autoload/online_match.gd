extends Node

# For developers to set from the outside, for example:
#   OnlineMatch.max_players = 8
#   OnlineMatch.client_version = 'v1.2'
var min_players := 2
var max_players := 2
var client_version := 'dev'
var ice_servers = [{ "urls": ["stun:stun.l.google.com:19302"] }]
enum NetworkRelay {
	AUTO,
	FORCED,
	DISABLED
}
var use_network_relay = NetworkRelay.AUTO

# Nakama variables:
var nakama_socket: NakamaSocket
var my_session_id: String: get = get_my_session_id
var match_id: String: get = get_match_id
var matchmaker_ticket: String: get = get_matchmaker_ticket

# WebRTC variables
var _webrtc_multiplayer: WebRTCMultiplayerPeer
var _webrtc_peers: Dictionary
var _webrtc_peers_connected: Dictionary

var players: Dictionary
var _next_peer_id: int

enum MatchState {
	LOBBY = 0,
	MATCHING = 1,
	CONNECTING = 2,
	WAITING_FOR_ENOUGH_PLAYERS = 3,
	READY = 4,
	PLAYING = 5,
}
var match_state: int = MatchState.LOBBY: get = get_match_state

enum MatchMode {
	NONE = 0,
	CREATE = 1,
	JOIN = 2,
	MATCHMAKER = 3,
}
var match_mode: int = MatchMode.NONE: get = get_match_mode

enum PlayerStatus {
	CONNECTING = 0,
	CONNECTED = 1,
}

enum MatchOpCode {
	WEBRTC_PEER_METHOD = 9001,
	JOIN_SUCCESS = 9002,
	JOIN_ERROR = 9003,
	CUSTOM_RPC = 9004,
}

signal error(message)
signal disconnected()

signal match_created(match_id)
signal match_joined(match_id)
signal matchmaker_matched(players)

signal player_joined(player)
signal player_left(player)
signal player_status_changed(player, status)

signal match_ready(players)
signal match_not_ready()

signal webrtc_peer_added (webrtc_peer, player)
signal webrtc_peer_removed (webrtc_peer, player)

class Player:
	var session_id: String
	var peer_id: int
	var username: String

	func _init(_session_id: String, _username: String, _peer_id: int) -> void:
		session_id = _session_id
		username = _username
		peer_id = _peer_id

	static func from_presence(presence: NakamaRTAPI.UserPresence, _peer_id: int) -> Player:
		return Player.new(presence.session_id, presence.username, _peer_id)

	static func from_dict(data: Dictionary) -> Player:
		return Player.new(data['session_id'], data['username'], int(data['peer_id']))

	func to_dict() -> Dictionary:
		return {
			session_id = session_id,
			username = username,
			peer_id = peer_id,
		}

	func _to_string() -> String:
		return "session_id: %s, peer_id: %d, username: %s" % [session_id, peer_id, username]

static func serialize_players(_players: Dictionary) -> Dictionary:
	var result := {}
	for key in _players:
		result[key] = _players[key].to_dict()
	return result

static func unserialize_players(_players: Dictionary) -> Dictionary:
	var result := {}
	for key in _players:
		result[key] = Player.from_dict(_players[key])
	return result

func _set_readonly_variable(_value) -> void:
	pass

func _set_nakama_socket(_nakama_socket: NakamaSocket) -> void:
	if nakama_socket == _nakama_socket:
		return

	if nakama_socket:
		nakama_socket.closed.disconnect(self._on_nakama_closed)
		nakama_socket.received_error.disconnect(self._on_nakama_error)
		nakama_socket.received_match_state.disconnect(self._on_nakama_match_state)
		nakama_socket.received_match_presence.disconnect(self._on_nakama_match_presence)
		nakama_socket.received_matchmaker_matched.disconnect(self._on_nakama_matchmaker_matched)

	nakama_socket = _nakama_socket
	if nakama_socket:
		nakama_socket.closed.connect(self._on_nakama_closed)
		nakama_socket.received_error.connect(self._on_nakama_error)
		nakama_socket.received_match_state.connect(self._on_nakama_match_state)
		nakama_socket.received_match_presence.connect(self._on_nakama_match_presence)
		nakama_socket.received_matchmaker_matched.connect(self._on_nakama_matchmaker_matched)

func create_match(_nakama_socket: NakamaSocket) -> void:
	leave()
	_set_nakama_socket(_nakama_socket)
	match_mode = MatchMode.CREATE

	var data = await nakama_socket.create_match_async()
	if data.is_exception():
		leave()
		error.emit("Failed to create match: " + str(data.get_exception().message))
	else:
		_on_nakama_match_created(data)

func join_match(_nakama_socket: NakamaSocket, _match_id: String) -> void:
	leave()
	_set_nakama_socket(_nakama_socket)
	match_mode = MatchMode.JOIN

	var data = await nakama_socket.join_match_async(_match_id)
	if data.is_exception():
		leave()
		error.emit("Unable to join match")
	else:
		_on_nakama_match_join(data)

func start_matchmaking(_nakama_socket: NakamaSocket, data: Dictionary = {}) -> void:
	leave()
	_set_nakama_socket(_nakama_socket)
	match_mode = MatchMode.MATCHMAKER

	if data.has('min_count'):
		data['min_count'] = max(min_players, data['min_count'])
	else:
		data['min_count'] = min_players

	if data.has('max_count'):
		data['max_count'] = min(max_players, data['max_count'])
	else:
		data['max_count'] = max_players

	if client_version != '':
		if not data.has('string_properties'):
			data['string_properties'] = {}
		data['string_properties']['client_version'] = client_version

		var query = '+properties.client_version:' + client_version
		if data.has('query'):
			data['query'] += ' ' + query
		else:
			data['query'] = query

	match_state = MatchState.MATCHING
	var result = await nakama_socket.add_matchmaker_async(data.get('query', '*'), data['min_count'], data['max_count'], data.get('string_properties', {}), data.get('numeric_properties', {}))
	if result.is_exception():
		leave()
		error.emit("Unable to join match making pool")
	else:
		matchmaker_ticket = result.ticket

func start_playing() -> void:
	assert(match_state == MatchState.READY)
	match_state = MatchState.PLAYING

func leave(close_socket: bool = false) -> void:
	if _webrtc_multiplayer:
		_webrtc_multiplayer.close()
		multiplayer.set_multiplayer_peer(null)

	# Nakama disconnect.
	if nakama_socket:
		if match_id:
			await nakama_socket.leave_match_async(match_id)
		elif matchmaker_ticket:
			await nakama_socket.remove_matchmaker_async(matchmaker_ticket)
		if close_socket:
			nakama_socket.close()
			_set_nakama_socket(null)

	# Initialize all the variables to their default state.
	my_session_id = ''
	match_id = ''
	matchmaker_ticket = ''
	_create_webrtc_multiplayer()
	_webrtc_peers = {}
	_webrtc_peers_connected = {}
	players = {}
	_next_peer_id = 1
	match_state = MatchState.LOBBY
	match_mode = MatchMode.NONE


func _create_webrtc_multiplayer() -> void:
	if _webrtc_multiplayer:
		_webrtc_multiplayer.peer_connected.disconnect(self._on_webrtc_peer_connected)
		_webrtc_multiplayer.peer_disconnected.disconnect(self._on_webrtc_peer_disconnected)

	_webrtc_multiplayer = WebRTCMultiplayerPeer.new()
	_webrtc_multiplayer.peer_connected.connect(self._on_webrtc_peer_connected)
	_webrtc_multiplayer.peer_disconnected.connect(self._on_webrtc_peer_disconnected)

func get_my_session_id() -> String:
	return my_session_id

func get_match_id() -> String:
	return match_id

func get_matchmaker_ticket() -> String:
	return matchmaker_ticket

func get_match_mode() -> int:
	return match_mode

func get_match_state() -> int:
	return match_state

func get_session_id(peer_id: int):
	for session_id in players:
		if players[session_id]['peer_id'] == peer_id:
			return session_id
	return null

func get_player_by_peer_id(peer_id: int) -> Player:
	var session_id = get_session_id(peer_id)
	if session_id:
		return players[session_id]
	return null

func get_player_names_by_peer_id() -> Dictionary:
	var result = {}
	for session_id in players:
		result[players[session_id]['peer_id']] = players[session_id]['username']
	return result

func get_players_by_peer_id() -> Dictionary:
	var result := {}
	for player in players.values():
		result[player.peer_id] = player
	return result

func get_sorted_players() -> Array:
	var sorted_players = players.values()
	if sorted_players.is_empty():
		return [Player.new("local", "local", 1)]
	sorted_players.sort_custom(func(a, b): return a.peer_id < b.peer_id)
	return sorted_players

func get_webrtc_peer(session_id: String) -> WebRTCPeerConnection:
	return _webrtc_peers.get(session_id, null)

func get_webrtc_peer_by_peer_id(peer_id: int) -> WebRTCPeerConnection:
	var player = get_player_by_peer_id(peer_id)
	if player:
		return _webrtc_peers.get(player.session_id, null)
	return null

func _on_nakama_error(data) -> void:
	print ("ERROR:")
	print(data)
	leave()
	error.emit("connection error")

func _on_nakama_closed() -> void:
	leave()
	disconnected.emit()

func _on_nakama_match_created(data: NakamaRTAPI.Match) -> void:
	match_id = data.match_id
	my_session_id = data.self_user.session_id
	var my_player = Player.from_presence(data.self_user, 1)
	players[my_session_id] = my_player
	_next_peer_id = 2

	_webrtc_multiplayer.create_mesh(1)
	multiplayer.set_multiplayer_peer(_webrtc_multiplayer)

	match_created.emit(match_id)
	player_joined.emit(my_player)
	player_status_changed.emit(my_player, PlayerStatus.CONNECTED)

func _check_enough_players() -> void:
	if players.size() >= min_players:
		match_state = MatchState.READY;
		match_ready.emit(players)
	else:
		match_state = MatchState.WAITING_FOR_ENOUGH_PLAYERS

func _on_nakama_match_presence(data: NakamaRTAPI.MatchPresenceEvent) -> void:
	for u in data.joins:
		if u.session_id == my_session_id:
			continue

		if match_mode == MatchMode.CREATE:
			if match_state == MatchState.PLAYING:
				# Tell this player that we've already started
				nakama_socket.send_match_state_async(match_id, MatchOpCode.JOIN_ERROR, JSON.stringify({
					target = u['session_id'],
					reason = 'Sorry! The match has already begun.',
				}))

			if players.size() < max_players:
				var new_player = Player.from_presence(u, _next_peer_id)
				_next_peer_id += 1
				players[u.session_id] = new_player
				player_joined.emit(new_player)
				player_status_changed.emit(new_player, PlayerStatus.CONNECTED)

				# Tell this player (and the others) about all the players peer ids.
				@warning_ignore("static_called_on_instance")
				nakama_socket.send_match_state_async(match_id, MatchOpCode.JOIN_SUCCESS, JSON.stringify({
					players = serialize_players(players),
					client_version = client_version,
				}))

				_check_enough_players()
				_webrtc_connect_peer(new_player)
			else:
				# Tell this player that we're full up!
				nakama_socket.send_match_state_async(match_id, MatchOpCode.JOIN_ERROR, JSON.stringify({
					target = u['session_id'],
					reason = 'Sorry! The match is full.,',
				}))
		elif match_mode == MatchMode.MATCHMAKER:
			player_joined.emit(players[u.session_id])
			_webrtc_connect_peer(players[u.session_id])

	for u in data.leaves:
		if u.session_id == my_session_id:
			continue
		if not players.has(u.session_id):
			continue

		var player = players[u.session_id]
		_webrtc_disconnect_peer(player)
		# If the host disconnects, this is the end!
		if player.peer_id == 1:
			leave()
			error.emit("Host has disconnected")
		else:
			players.erase(u.session_id)
			player_left.emit(player)

			if players.size() < min_players:
				# If state was previously ready, but this brings us below the minimum players,
				# then we aren't ready anymore.
				if match_state == MatchState.READY || match_state == MatchState.PLAYING:
					match_not_ready.emit()

func _on_nakama_match_join(data: NakamaRTAPI.Match) -> void:
	match_id = data.match_id
	my_session_id = data.self_user.session_id

	if match_mode == MatchMode.JOIN:
		match_joined.emit(match_id)
	elif match_mode == MatchMode.MATCHMAKER:
		_check_enough_players()
		for u in data.presences:
			if u.session_id == my_session_id:
					continue
			_webrtc_connect_peer(players[u.session_id])

func _on_nakama_matchmaker_matched(data: NakamaRTAPI.MatchmakerMatched) -> void:
	if data.is_exception():
		leave()
		error.emit("Matchmaker error")
		return

	my_session_id = data.self_user.presence.session_id

	# Use the list of users to assign peer ids.
	for u in data.users:
		players[u.presence.session_id] = Player.from_presence(u.presence, 0)
	var session_ids = players.keys();
	session_ids.sort()
	for session_id in session_ids:
		players[session_id].peer_id = _next_peer_id
		_next_peer_id += 1

	# Initialize multiplayer using our peer id
	_webrtc_multiplayer.create_mesh(players[my_session_id].peer_id)
	multiplayer.set_multiplayer_peer(_webrtc_multiplayer)

	matchmaker_matched.emit(players)
	for session_id in players:
		player_status_changed.emit(players[session_id], PlayerStatus.CONNECTED)

	# Join the match.
	var result = await nakama_socket.join_matched_async(data)
	if result.is_exception():
		leave()
		error.emit("Unable to join match")
	else:
		_on_nakama_match_join(result)

func _on_nakama_match_state(data: NakamaRTAPI.MatchData):
	var json = JSON.new()
	var json_error = json.parse(data.data)
	if json_error != OK:
		return
	var content = json.get_data()
	if data.op_code == MatchOpCode.WEBRTC_PEER_METHOD:
		if content['target'] == my_session_id:
			var session_id = data.presence.session_id
			if not _webrtc_peers.has(session_id):
				return
			var webrtc_peer = _webrtc_peers[session_id]
			match content['method']:
				'set_remote_description':
					webrtc_peer.set_remote_description(content['type'], content['sdp'])
				'add_ice_candidate':
					if _webrtc_check_ice_candidate(content['name']):
						print ("Receiving ice candidate: %s" % content['name'])
						webrtc_peer.add_ice_candidate(content['media'], content['index'], content['name'])
				'reconnect':
					_webrtc_multiplayer.remove_peer(players[session_id]['peer_id'])
					_webrtc_reconnect_peer(players[session_id])
	if data.op_code == MatchOpCode.JOIN_SUCCESS && match_mode == MatchMode.JOIN:
		var host_client_version = content.get('client_version', '')
		if client_version != host_client_version:
			leave()
			error.emit("Client version doesn't match host")
			return

		@warning_ignore("static_called_on_instance")
		var content_players = unserialize_players(content['players'])
		for session_id in content_players:
			if not players.has(session_id):
				players[session_id] = content_players[session_id]
				_webrtc_connect_peer(players[session_id])
				player_joined.emit(players[session_id])
				if session_id == my_session_id:
					_webrtc_multiplayer.initialize(players[session_id].peer_id)
					multiplayer.set_multiplayer_peer(_webrtc_multiplayer)
					player_status_changed.emit(players[session_id], PlayerStatus.CONNECTED)
		_check_enough_players()
	if data.op_code == MatchOpCode.JOIN_ERROR:
		if content['target'] == my_session_id:
			leave()
			error.emit(content['reason'])

func _webrtc_connect_peer(player: Player) -> void:
	# Don't add the same peer twice!
	if _webrtc_peers.has(player.session_id):
		return

	# If the match was previously ready, then we need to switch back to not ready.
	if match_state == MatchState.READY:
		match_not_ready.emit()

	# If we're already PLAYING, then this is a reconnect attempt, so don't mess with the state.
	# Otherwise, change state to CONNECTING because we're trying to connect to all peers.
	if match_state != MatchState.PLAYING:
		match_state = MatchState.CONNECTING

	var webrtc_peer := WebRTCPeerConnection.new()
	webrtc_peer.initialize({
		"iceServers": ice_servers,
	})
	webrtc_peer.session_description_created.connect(self._on_webrtc_peer_session_description_created.bind(player.session_id))
	webrtc_peer.ice_candidate_created.connect(self._on_webrtc_peer_ice_candidate_created.bind(player.session_id))

	_webrtc_peers[player.session_id] = webrtc_peer

	#get_tree().multiplayer._del_peer(u['peer_id'])
	_webrtc_multiplayer.add_peer(webrtc_peer, player.peer_id, 0)

	webrtc_peer_added.emit(webrtc_peer, player)

	if my_session_id.casecmp_to(player.session_id) < 0:
		print("Making offer from session ")
		var result = webrtc_peer.create_offer()
		if result != OK:
			error.emit("webrtc offer error")

func _webrtc_disconnect_peer(player: Player) -> void:
	var webrtc_peer = _webrtc_peers[player.session_id]
	webrtc_peer_removed.emit(webrtc_peer, player)
	webrtc_peer.close()
	_webrtc_peers.erase(player.session_id)
	_webrtc_peers_connected.erase(player.session_id)

func _webrtc_reconnect_peer(player: Player) -> void:
	var old_webrtc_peer = _webrtc_peers[player.session_id]
	if old_webrtc_peer:
		webrtc_peer_removed.emit(old_webrtc_peer, player)
		old_webrtc_peer.close()

	_webrtc_peers_connected.erase(player.session_id)
	_webrtc_peers.erase(player.session_id)

	print ("Starting WebRTC reconnect...")

	_webrtc_connect_peer(player)

	player_status_changed.emit(player, PlayerStatus.CONNECTING)

	if match_state == MatchState.READY:
		match_state = MatchState.CONNECTING
		match_not_ready.emit()

func _webrtc_check_ice_candidate(name: String) -> bool:
	if use_network_relay == NetworkRelay.AUTO:
		return true

	var is_relay: bool = "typ relay" in name

	if use_network_relay == NetworkRelay.FORCED:
		return is_relay
	return !is_relay

func _on_webrtc_peer_session_description_created(type: String, sdp: String, session_id: String) -> void:
	var webrtc_peer = _webrtc_peers[session_id]
	webrtc_peer.set_local_description(type, sdp)

	# Send this data to the peer so they can call call .set_remote_description().
	nakama_socket.send_match_state_async(match_id, MatchOpCode.WEBRTC_PEER_METHOD, JSON.stringify({
		method = "set_remote_description",
		target = session_id,
		type = type,
		sdp = sdp,
	}))

func _on_webrtc_peer_ice_candidate_created(media: String, index: int, name: String, session_id: String) -> void:
	if not _webrtc_check_ice_candidate(name):
		return

	#print ("Sending ice candidate: %s" % name)

	# Send this data to the peer so they can call .add_ice_candidate()
	nakama_socket.send_match_state_async(match_id, MatchOpCode.WEBRTC_PEER_METHOD, JSON.stringify({
		method = "add_ice_candidate",
		target = session_id,
		media = media,
		index = index,
		name = name,
	}))

func _on_webrtc_peer_connected(peer_id: int) -> void:
	for session_id in players:
		if players[session_id]['peer_id'] == peer_id:
			_webrtc_peers_connected[session_id] = true
			print ("WebRTC peer connected: " + str(peer_id))
			player_status_changed.emit(players[session_id], PlayerStatus.CONNECTED)

	# We have a WebRTC peer for each connection to another player, so we'll have one less than
	# the number of players (ie. no peer connection to ourselves).
	if _webrtc_peers_connected.size() == players.size() - 1:
		if players.size() >= min_players:
			# All our peers are good, so we can assume RPC will work now.
			match_state = MatchState.READY;
			match_ready.emit(players)
		else:
			match_state = MatchState.WAITING_FOR_ENOUGH_PLAYERS

func _on_webrtc_peer_disconnected(peer_id: int) -> void:
	print ("WebRTC peer disconnected: " + str(peer_id))

	for session_id in players:
		if players[session_id]['peer_id'] == peer_id:
			# We initiate the reconnection process from only one side (the offer side).
			if my_session_id.casecmp_to(session_id) < 0:
				# Tell the remote peer to restart their connection.
				nakama_socket.send_match_state_async(match_id, MatchOpCode.WEBRTC_PEER_METHOD, JSON.stringify({
					method = "reconnect",
					target = session_id,
				}))

				# Initiate reconnect on our end now (the other end will do it when they receive
				# the message above).
				_webrtc_reconnect_peer(players[session_id])
