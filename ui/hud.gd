extends Control

class_name Hud

@export_group("Internal")
@export var peer: Label
@export var time: Label
@export var coins: Label
@export var main_message: Label
@export var bottom_message: Label

enum MessageType {
	MAIN,
	BOTTOM,
}

@onready var message_label = {
	MessageType.MAIN: main_message,
	MessageType.BOTTOM: bottom_message,
}

var message_generation = {
	MessageType.MAIN: 0,
	MessageType.BOTTOM: 0,
}

var message_tween = {
	MessageType.MAIN: null,
	MessageType.BOTTOM: null,
}

func _ready():
	for label in message_label.values():
		label.hide()

func set_peer(peer_id: int):
	peer.text = "Peer: %d" % peer_id

func set_time(time_secs: int):
	var minutes = time_secs / 60
	var seconds = time_secs % 60
	time.text = "%02d:%02d" % [minutes, seconds]

func set_coins(_coins: int, target: int):
	if target == -1:
		coins.text = "Coins: %d/<inf>" % _coins
	else:
		coins.text = "Coins: %d/%d" % [_coins, target]

func show_main_message(message: String, timeout: float = 5.0) -> void:
	_show_message.rpc(message, MessageType.MAIN, timeout)

func show_bottom_message(message: String, timeout: float = 5.0) -> void:
	_show_message.rpc(message, MessageType.BOTTOM, timeout)

@rpc("call_local")
func _show_message(message: String, message_type: MessageType, timeout: float = 5.0) -> void:
	var label = message_label[message_type]
	label.text = message
	message_generation[message_type] += 1
	if message_tween[message_type]:
		message_tween[message_type].kill()
	var current_generation = message_generation[message_type]
	# If new message has long timeout and label is not visible do fade in.
	# Otherwise just show directly.
	if timeout > 3.0 and not label.visible:
		timeout -= 1.0
		label.modulate.a = 0.0
		label.show()
		var tween = create_tween()
		tween.tween_property(label, "modulate:a", 1, 1.0)
		message_tween[message_type] = tween
		await tween.finished
		if current_generation != message_generation[message_type]:
			return
	else:
		label.modulate.a = 1.0
		label.show()
	var fade_out_time = timeout - 1.0
	var time_left: float
	if fade_out_time > 0:
		time_left = 1.0
		await get_tree().create_timer(fade_out_time).timeout
		if current_generation != message_generation[message_type]:
			return
	else:
		time_left = timeout
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0, time_left)
	message_tween[message_type] = tween
	await tween.finished
	if current_generation != message_generation[message_type]:
		return
	label.hide()
