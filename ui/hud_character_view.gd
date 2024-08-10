extends Control

class_name HudCharacterView

var character: Character

signal config_button_pressed
signal readiness_updated(ready: bool)
signal view_log_requested(logging_component: LoggingComponent)
signal upgrade_window_requested(character: Character)

func _ready():
	%ConfigContainer.hide()
	%HudStatusDisplay.clear()

func initialize(character_: Character) -> void:
	character = character_
	var health = HealthComponent.get_or_die(character)
	health.health_updated.connect(_on_health_updated)
	# Set health to current value (in case we missed the signal setting initial health,
	# which happens when we play a level through F6). We only can do it if
	# we missed the signal, otherwise both updates happen in the same frame
	# and the progress bar seems confused.
	if health.health > 0:
		_set_health(health.health, health.max_health)
	var status = Component.get_status_component_or_die(character)
	status.statuses_changed.connect(_on_statuses_changed)
	var behavior = character.get_component_or_die(BehaviorComponent)
	behavior.behavior_updated.connect(_on_behavior_updated)
	var state = Component.get_persistent_game_state_component_or_die(character).state
	%Title.text = state.name
	var effect_actuator_component = character.get_component_or_die(EffectActuatorComponent)
	effect_actuator_component.relics_changed.connect(_on_relics_changed)

func is_local() -> bool:
	if OnlineMatch.match_mode == OnlineMatch.MatchMode.NONE:
		return true
	var multiplayer_id = multiplayer.get_unique_id()
	return multiplayer_id == character.peer_id

func show_buttons(show: bool, text: String) -> void:
	if show:
		if not text.is_empty():
			%ConfigButton.text = text
		%ConfigContainer.show()
		%ReadyButton.set_pressed_no_signal(false)
		if is_local():
			%ConfigButtons.show()
		else:
			%ReadyButton.disabled = true
	else:
		%ConfigContainer.hide()

func _set_health(health: int, max_health: int):
	%HealthBar.value = health
	%HealthBar.max_value = max_health
	%HealthLabel.text = "%d / %d" % [health, max_health]

func _on_health_updated(health_update: HealthComponent.HealthUpdate):
	_set_health(health_update.health, health_update.max_health)

func _on_statuses_changed(statuses: Array):
	%HudStatusDisplay.clear()
	for status_id in statuses:
		%HudStatusDisplay.add_status(status_id)

func _on_relics_changed(relics: Array[RelicDef]):
	%HudRelicDisplay.clear()
	for relic in relics:
		%HudRelicDisplay.add_relic(relic)

func _on_behavior_updated(action_name: StringName, _target: Target):
	# TODO: Do something with target, e.g. hovering could highlight the
	# target in the level. Or at least add target description.
	%ActionLabel.text = str(action_name) if action_name != ActionDef.NoAction else "Idle"

func _on_config_button_pressed():
	config_button_pressed.emit()

func _on_ready_button_toggled(toggled_on: bool):
	_ready_button_toggled(toggled_on)
	_on_peer_ready_button_toggled.rpc(toggled_on)

@rpc("any_peer")
func _on_peer_ready_button_toggled(toggled_on: bool):
	_ready_button_toggled(toggled_on)
	%ReadyButton.set_pressed_no_signal(toggled_on)

func _ready_button_toggled(toggled_on: bool):
	readiness_updated.emit(toggled_on)

func _on_view_log_button_pressed():
	view_log_requested.emit(Component.get_logging_component_or_die(character))

func _on_upgrade_button_pressed():
	upgrade_window_requested.emit(character)
