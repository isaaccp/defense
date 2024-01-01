extends Control

class_name Hud

@export_group("Internal")
@export var peer: Label
@export var time: Label
@export var main_message: Label
@export var bottom_message: Label

var characters: Array[Character]
var characters_ready: Dictionary

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
const hud_tower_view_scene = preload("res://ui/hud_tower_view.tscn")
const programming_ui_scene = preload("res://ui/programming_ui.tscn")

signal all_ready
signal behavior_modified(character_idx: int, behavior: Behavior)

func _ready():
	for label in message_label.values():
		label.hide()

func set_characters(character_node: Node) -> void:
	characters.clear()
	for character in character_node.get_children():
		characters.append(character)

	for view in %CharacterViews.get_children():
		view.queue_free()
		
	for i in characters.size():
		var view = hud_character_view_scene.instantiate() as HudCharacterView
		view.initialize(characters[i])
		%CharacterViews.add_child(view)

func set_towers(towers: Node) -> void:
	for view in %TowerHud.get_children():
		view.queue_free()
	# For now let's handle only one tower.
	var tower = towers.get_child(0)
	var view = hud_tower_view_scene.instantiate() as HudTowerView
	view.initialize(tower)
	%TowerHud.add_child(view)

func set_victory_loss(victory_loss: VictoryLossConditionComponent):
	%VictoryLoss.initialize(victory_loss)
	show_victory_loss_text()

func show_victory_loss(visible: bool = true):
	%VictoryLoss.visible = visible
	
func show_victory_loss_text(visible: bool = true):
	if visible:
		show_victory_loss(true)
	%VictoryLoss.show_text(visible)

func start_behavior_setup():
	start_character_setup("Configure Behavior", _on_configure_behavior_pressed)
	
func start_character_setup(text: String, callback: Callable):
	show_character_button(true, text)
	characters_ready.clear()
	for i in %CharacterViews.get_child_count():
		var view = %CharacterViews.get_child(i)
		view.config_button_pressed.connect(callback.bind(i))
		view.readiness_updated.connect(_on_readiness_updated.bind(i))
	
func _on_readiness_updated(ready: bool, character_idx: int):
	if ready:
		characters_ready[character_idx] = true
		if characters_ready.size() == characters.size():
			# Clear for next time.
			characters_ready.clear()
			all_ready.emit()
	else:
		characters_ready.erase(character_idx)
		
func _on_configure_behavior_pressed(character_idx: int):
	var character = characters[character_idx]
	%ProgrammingUIParent.show()
	for child in %ProgrammingUIParent.get_children():
		child.queue_free()
	var programming_ui = programming_ui_scene.instantiate() as ProgrammingUI
	%ProgrammingUIParent.add_child(programming_ui)
	programming_ui.initialize(character)
	programming_ui.saved.connect(_save_and_close.bind(character_idx))
	programming_ui.canceled.connect(_close)
	show_character_button(false)

func _save_and_close(behavior: Behavior, character_idx: int):
	behavior_modified.emit(character_idx, behavior)
	_close()

func _close():
	for child in %ProgrammingUIParent.get_children():
			child.queue_free()
	%ProgrammingUIParent.hide()
	show_character_button(true)

func show_character_button(show: bool, text: String = ""):
	for view in %CharacterViews.get_children():
		view.show_button(show, text)

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
