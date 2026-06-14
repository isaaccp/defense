extends Control

class_name HudCharacterView

var character: Character
# Set when the view is driven by a GameplayCharacter directly (reward stage,
# etc.) instead of a runtime Character node + components.
var gameplay_character: GameplayCharacter

signal config_button_pressed
signal readiness_updated(ready: bool)
signal view_log_requested(character: Character)

signal card_clicked(gameplay_character: GameplayCharacter)

func _ready():
	%ConfigContainer.hide()
	%PreferredTargetLabel.hide()
	%HudStatusDisplay.clear()

## Reward-stage / non-combat init. Reads HP/XP/relics directly from the
## GameplayCharacter resource — no Character node or components required.
## Hides in-combat-only widgets (focus bar, action, preferred target,
## config buttons, status display).
func initialize_from_gameplay_character(gc: GameplayCharacter, relic_library: RelicLibrary) -> void:
	gameplay_character = gc
	%Title.text = gc.name
	# HP bar.
	%HealthBar.max_value = gc.attributes.health
	%HealthBar.value = gc.health
	%HealthBar.get_child(0).text = "%d / %d" % [gc.health, gc.attributes.health]
	# Hide combat-only stuff.
	%ActionLabel.hide()
	%PreferredTargetLabel.hide()
	%ConfigContainer.hide()
	%HudStatusDisplay.clear()
	%HudStatusDisplay.hide()
	# XP.
	%XPLabel.text = "XP: %d" % gc.xp
	%XPLabel.show()
	# Relics.
	%HudRelicDisplay.clear()
	if relic_library:
		for relic_name in gc.relics:
			var relic := relic_library.get_relic(relic_name)
			if relic:
				%HudRelicDisplay.add_relic(relic)
	# Forwarded click for character pickers (relic recipient, trainer
	# character pick). Disabled by default; the host screen toggles it.
	if not gui_input.is_connected(_on_card_gui_input):
		gui_input.connect(_on_card_gui_input)
	mouse_filter = Control.MOUSE_FILTER_STOP

## Toggle whether this card emits `card_clicked` on press. Reward stage
## flips this on for "pick a character" sub-flows. Adds a bright pulsing
## border so the player can see what's expected of them.
func set_pickable(on: bool) -> void:
	_pickable = on
	if on:
		add_theme_stylebox_override("panel", _pickable_stylebox())
		if _pulse_tween and _pulse_tween.is_valid():
			_pulse_tween.kill()
		_pulse_tween = create_tween().set_loops()
		_pulse_tween.tween_property(self, "modulate", Color(1.18, 1.15, 0.95, 1), 0.55)
		_pulse_tween.tween_property(self, "modulate", Color.WHITE, 0.55)
	else:
		remove_theme_stylebox_override("panel")
		if _pulse_tween and _pulse_tween.is_valid():
			_pulse_tween.kill()
		_pulse_tween = null
		modulate = Color.WHITE

func _pickable_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.14, 0.17, 1.0)
	sb.border_color = Color(1.0, 0.85, 0.30, 1.0)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	return sb

var _pickable: bool = false
var _pulse_tween: Tween

func _on_card_gui_input(event: InputEvent) -> void:
	if not _pickable:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if gameplay_character:
			card_clicked.emit(gameplay_character)

func initialize(character_: Character) -> void:
	character = character_
	var vitals = character.get_component_or_die(VitalsComponent) as VitalsComponent
	vitals.vital_updated.connect(_on_vital_updated)
	# Set health to current value (in case we missed the signal setting initial health,
	# which happens when we play a level through F6). We only can do it if
	# we missed the signal, otherwise both updates happen in the same frame
	# and the progress bar seems confused.
	_update_vital(vitals, VitalsComponent.VitalType.HEALTH)
	var status = character.get_component_or_die(StatusComponent) as StatusComponent
	status.statuses_changed.connect(_on_statuses_changed)
	var behavior = character.get_component_or_die(BehaviorComponent)
	behavior.behavior_updated.connect(_on_behavior_updated)
	behavior.preferred_target_changed.connect(_on_preferred_target_changed)
	%Title.text = character.actor_name
	var effect_actuator_component = character.get_component_or_die(EffectActuatorComponent)
	effect_actuator_component.relics_changed.connect(_on_relics_changed)
	# One-off call to add existing relics.
	_on_relics_changed(effect_actuator_component.relics)

func _vital_bar(vital_type: VitalsComponent.VitalType) -> ProgressBar:
	if vital_type == VitalsComponent.VitalType.HEALTH:
		return %HealthBar
	else:
		assert(false)
		return null
		
func _update_vital(vitals: VitalsComponent, vital_type: VitalsComponent.VitalType) -> void:
	if vitals.get_vital_current(vital_type) > 0:
		_set_vital(vital_type, vitals.get_vital_current(vital_type),
				   vitals.get_vital_max(vital_type))

func _set_vital(vital: VitalsComponent.VitalType, current: int, max: int):
	var bar = _vital_bar(vital)
	bar.value = current
	bar.max_value = max
	# Each bar has a single child which is a label.
	bar.get_child(0).text = "%d / %d" % [current, max]
	
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

func _on_vital_updated(vital_update: VitalsComponent.VitalUpdate):
	_set_vital(vital_update.type, int(vital_update.current_value), int(vital_update.max_value))

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

func _on_preferred_target_changed(preferred: Actor):
	if preferred:
		%PreferredTargetLabel.text = "Target: %s" % preferred.actor_name
		%PreferredTargetLabel.show()
	else:
		%PreferredTargetLabel.hide()

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
	view_log_requested.emit(character)
