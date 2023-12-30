extends Control

class_name Hud

@export_group("Internal")
@export var peer: Label
@export var time: Label
@export var main_message: Label
@export var bottom_message: Label
@export var character_views: Container

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

const hud_character_view_scene = preload("res://ui/hud_character_view.tscn")
const programming_ui_scene = preload("res://ui/programming_ui.tscn")

var characters_ready = {}

signal config_ready

func _ready():
	for label in message_label.values():
		label.hide()

func set_characters(characters: Node) -> void:
	for i in characters.get_child_count():
		var character = characters.get_child(i)
		var view = hud_character_view_scene.instantiate() as HudCharacterView
		view.initialize(character)
		view.configure_behavior_selected.connect(_on_configure_behavior_selected.bind(character))
		view.readiness_updated.connect(_on_readiness_updated.bind(i))
		character_views.add_child(view)
		
func _on_configure_behavior_selected(character: Character):
	%ProgrammingUIParent.show()
	for child in %ProgrammingUIParent.get_children():
		child.queue_free()
	var programming_ui = programming_ui_scene.instantiate() as ProgrammingUI
	programming_ui.initialize(character)
	programming_ui.done.connect(_close_programming_ui)
	%ProgrammingUIParent.add_child(programming_ui)
	show_character_config(false)

func _close_programming_ui():
	for child in %ProgrammingUIParent.get_children():
			child.queue_free()
	%ProgrammingUIParent.hide()
	show_character_config(true)
			
func _on_readiness_updated(ready: bool, character_idx: int):
	if ready:
		characters_ready[character_idx] = true
		if characters_ready.size() == character_views.get_child_count():
			config_ready.emit()
	else:
		characters_ready.erase(character_idx)
		
func show_character_config(show: bool):
	for view in character_views.get_children():
		view.show_config(show)

func set_peer(peer_id: int) -> void:
	peer.text = "Peer: %d" % peer_id

func set_time(time_secs: int) -> void:
	var minutes = time_secs / 60
	var seconds = time_secs % 60
	time.text = "%02d:%02d" % [minutes, seconds]

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
