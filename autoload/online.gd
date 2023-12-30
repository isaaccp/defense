extends Node

var nakama_server_key: String = 'defaultkey'
var nakama_host: String = 'localhost'
var nakama_port: int = 7350
var nakama_scheme: String = 'http'

var nakama_client: NakamaClient: get = get_nakama_client

var nakama_session: NakamaSession: set = set_nakama_session
signal session_changed(nakama_session: NakamaSession)

var nakama_socket: NakamaSocket
# Internal variable for initializing the socket.
var _nakama_socket_connecting := false
signal socket_connected(nakama_socket: NakamaSocket)

func _ready() -> void:
	pass

func get_nakama_client() -> NakamaClient:
	if nakama_client == null:
		nakama_client = Nakama.create_client(
			nakama_server_key,
			nakama_host,
			nakama_port,
			nakama_scheme,
			Nakama.DEFAULT_TIMEOUT,
			NakamaLogger.LOG_LEVEL.ERROR)
	return nakama_client

func set_nakama_session(_nakama_session: NakamaSession) -> void:
	nakama_session = _nakama_session
	session_changed.emit(nakama_session)

func connect_nakama_socket() -> void:
	if nakama_socket != null:
		return
	if _nakama_socket_connecting:
		return
	_nakama_socket_connecting = true

	var new_socket = Nakama.create_socket_from(nakama_client)
	var connected : NakamaAsyncResult = await new_socket.connect_async(nakama_session)
	if connected.is_exception():
		print("An error occurred: %s" % connected)
		return
	nakama_socket = new_socket
	_nakama_socket_connecting = false

	socket_connected.emit(nakama_socket)

func is_nakama_socket_connected() -> bool:
	return nakama_socket != null && nakama_socket.is_connected_to_host()
