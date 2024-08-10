extends Control

class_name Hud

@export_group("Internal")
@export var peer: Label
@export var time: Label

var characters: Array[Character]
var characters_ready: Dictionary
var behavior_library: BehaviorLibrary
var relic_choices: Array[RelicDef]

enum MessageType {
	MAIN,
	BOTTOM,
}

@onready var message_label = {
	MessageType.MAIN: %MainMessage,
	MessageType.BOTTOM: %BottomMessage,
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
const relic_choice_window_scene = preload("res://ui/relic_choice_window.tscn")

signal all_ready
signal behavior_modified(character_idx: int, behavior: StoredBehavior)
signal restart_requested
signal end_level_confirmed
signal view_log_requested(logging_component: LoggingComponent)
signal upgrade_window_requested(character: Character)
signal play_controls_play_pressed
signal play_controls_pause_pressed

func _ready():
	for label in message_label.values():
		label.hide()
	%PlayControls.initialize(self)

func set_behavior_library(behavior_library: BehaviorLibrary):
	self.behavior_library = behavior_library

func set_characters(character_node: Node) -> void:
	characters.clear()
	for character in character_node.get_children():
		characters.append(character)

	for view in %CharacterViews.get_children():
		%CharacterViews.remove_child(view)
		view.queue_free()

	for i in characters.size():
		var view = hud_character_view_scene.instantiate() as HudCharacterView
		view.initialize(characters[i])
		view.config_button_pressed.connect(_on_configure_behavior_pressed.bind(i))
		view.readiness_updated.connect(_on_readiness_updated.bind(i))
		view.view_log_requested.connect(_on_view_log_requested)
		view.upgrade_window_requested.connect(_on_upgrade_window_requested)
		%CharacterViews.add_child(view)

func set_towers(towers: Node) -> void:
	for view in %TowerHud.get_children():
		view.queue_free()
	if towers.get_child_count() == 0:
		return
	# For now let's handle only one tower.
	var tower = towers.get_child(0)
	var view = hud_tower_view_scene.instantiate() as HudTowerView
	view.initialize(tower)
	%TowerHud.add_child(view)

func set_level_options(selected_relics: Array[RelicDef]):
	var has_relics = len(selected_relics) > 0
	%SelectRelicButton.visible = has_relics
	relic_choices = selected_relics

func show_play_controls(show: bool = true):
	%PlayControls.visible = show

func set_victory_loss(victory_loss: VictoryLossConditionComponent):
	%VictoryLoss.initialize(victory_loss)
	show_victory_loss_text()

func show_victory_loss(show: bool = true):
	%VictoryLoss.visible = show

func show_victory_loss_text(show: bool = true):
	if show:
		show_victory_loss(true)
	%VictoryLoss.show_text(show)

func start_character_setup(all_ready_callback: Callable):
	# TODO: Need to disconnect.
	all_ready.connect(all_ready_callback, CONNECT_ONE_SHOT)
	show_character_buttons(true)

func _reset_character_setup():
	# Clear for next time.
	characters_ready.clear()

func _on_readiness_updated(ready: bool, character_idx: int):
	if ready:
		characters_ready[character_idx] = true
		if characters_ready.size() == characters.size():
			all_ready.emit()
			_reset_character_setup()
	else:
		characters_ready.erase(character_idx)

func _on_configure_behavior_pressed(character_idx: int):
	var character = characters[character_idx]
	%ProgrammingUIParent.show()
	for child in %ProgrammingUIParent.get_children():
		child.queue_free()
	var programming_ui = programming_ui_scene.instantiate() as ProgrammingUI
	var gameplay_character = Component.get_persistent_game_state_component_or_die(character).state
	programming_ui.initialize("Configuring behavior for %s" % gameplay_character.name, gameplay_character.behavior, gameplay_character.acquired_skills, behavior_library)
	%ProgrammingUIParent.add_child(programming_ui)
	programming_ui.saved.connect(_save_and_close.bind(character_idx))
	programming_ui.canceled.connect(_close)
	show_character_buttons(false)

func _save_and_close(behavior: StoredBehavior, character_idx: int):
	behavior_modified.emit(character_idx, behavior)
	_close()

func _close():
	for child in %ProgrammingUIParent.get_children():
			child.queue_free()
	%ProgrammingUIParent.hide()
	show_character_buttons(true)

func show_character_buttons(show: bool, text: String = ""):
	for view in %CharacterViews.get_children():
		view.show_buttons(show, text)

func set_peer(peer_id: int) -> void:
	peer.text = "Peer: %d" % peer_id

func set_time(time_secs: int) -> void:
	@warning_ignore("integer_division")
	var minutes = time_secs / 60
	var seconds = time_secs % 60
	time.text = "%02d:%02d" % [minutes, seconds]

func show_main_message(message: String, timeout: float = 5.0) -> void:
	# Call separately instead of with "call_local" as otherwise it can't await.
	_show_message.rpc(message, MessageType.MAIN, timeout)
	await _show_message(message, MessageType.MAIN, timeout)

func hide_main_message() -> void:
	show_main_message("", 0.0)

func show_bottom_message(message: String, timeout: float = 5.0) -> void:
	# Call separately instead of with "call_local" as otherwise it can't await.
	_show_message.rpc(message, MessageType.BOTTOM, timeout)
	await _show_message(message, MessageType.BOTTOM, timeout)

@rpc
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
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(label, "modulate:a", 0, time_left)
	message_tween[message_type] = fade_out_tween
	await fade_out_tween.finished
	if current_generation != message_generation[message_type]:
		return
	label.hide()

# For testing.
func character_view_count() -> int:
	return %CharacterViews.get_child_count()

func character_view(i: int) -> HudCharacterView:
	return %CharacterViews.get_child(i)

func _on_play_controls_restart_pressed():
	restart_requested.emit()

func _on_view_log_requested(logging_component: LoggingComponent):
	view_log_requested.emit(logging_component)

func _on_upgrade_window_requested(character: Character):
	upgrade_window_requested.emit(character)

func _on_play_controls_play_pressed():
	play_controls_play_pressed.emit()

func _on_play_controls_pause_pressed():
	play_controls_pause_pressed.emit()

func _on_select_relic_button_pressed():
	var relic_window = relic_choice_window_scene.instantiate() as RelicChoiceWindow
	%LevelOptionsParent.add_child(relic_window)
	relic_window.initialize(relic_choices, characters)
	relic_window.relic_selected.connect(_on_relic_selected)
	relic_window.relic_selection_canceled.connect(_on_relic_selection_canceled)
	relic_window.popup()

func _on_relic_selected(relic_name: StringName, character: Character):
	var effect_actuator_component = character.get_component_or_die(EffectActuatorComponent)
	effect_actuator_component.add_relic(relic_name)
	%SelectRelicButton.disabled = true

func _on_relic_selection_canceled():
	pass
