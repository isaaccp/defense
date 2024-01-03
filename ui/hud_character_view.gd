extends Control

class_name HudCharacterView

var character: Character

signal config_button_pressed
signal readiness_updated(ready: bool)
signal view_log_requested(logging_component: LoggingComponent)
signal upgrade_window_requested(character: Character)

@onready var hud_status_display: HudStatusDisplay = %HudStatusDisplay

func _ready():
	%ConfigContainer.hide()
	hud_status_display.clear()

func initialize(character_: Character) -> void:
	character = character_
	var health = Component.get_or_die(character, HealthComponent.component) as HealthComponent
	health.health_updated.connect(_on_health_updated)
	var status = Component.get_or_die(character, StatusComponent.component) as StatusComponent
	status.statuses_changed.connect(_on_statuses_changed)
	var behavior = Component.get_or_die(character, BehaviorComponent.component) as BehaviorComponent
	behavior.behavior_updated.connect(_on_behavior_updated)
	%Title.text = character.short_name()

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

func _on_health_updated(health_update: HealthComponent.HealthUpdate):
	%HealthBar.max_value = health_update.max_health
	%HealthBar.value = health_update.health
	%HealthLabel.text = "%d / %d" % [health_update.health, health_update.max_health]

func _on_statuses_changed(statuses: Array):
	hud_status_display.clear()
	for status_id in statuses:
		hud_status_display.add_status(status_id)

func _on_behavior_updated(action_id: ActionDef.Id, target: Target):
	# TODO: Do something with target, e.g. hovering could highlight the
	# target in the level.
	var text = "Idle"
	if action_id != ActionDef.Id.UNSPECIFIED:
		text = "%s" % ActionDef.action_name(action_id)
	%ActionLabel.text = text

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
