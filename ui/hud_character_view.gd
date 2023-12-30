extends Control

class_name HudCharacterView

var character: Character

signal configure_behavior_selected
signal readiness_updated(ready: bool)

func _ready():
	%ConfigContainer.hide()
	
func initialize(character_: Character) -> void:
	character = character_
	character.health_updated.connect(_on_health_updated)
	%Title.text = character.short_name()
	_on_health_updated(character.hit_points, character.max_hit_points)

func is_local() -> bool:
	if OnlineMatch.match_mode == OnlineMatch.MatchMode.NONE:
		return true
	var multiplayer_id = multiplayer.get_unique_id()
	return multiplayer_id == character.peer_id
	
func show_config(show: bool) -> void:
	if show:
		%ConfigContainer.show()
		if is_local():
			%ConfigureBehaviorButton.show()
		else:
			%ReadyButton.disabled = true
	else:
		%ConfigContainer.hide()

func _on_health_updated(hit_points: int, max_hit_points: int):
	%HealthBar.max_value = max_hit_points
	%HealthBar.value = hit_points
	%HealthLabel.text = "%d / %d" % [hit_points, max_hit_points]
	
func _on_configure_behavior_button_pressed():
	configure_behavior_selected.emit()

func _on_ready_button_toggled(toggled_on: bool):
	_ready_button_toggled(toggled_on)
	_on_peer_ready_button_toggled.rpc(toggled_on)
	
@rpc("any_peer")
func _on_peer_ready_button_toggled(toggled_on: bool):
	_ready_button_toggled(toggled_on)
	%ReadyButton.set_pressed_no_signal(toggled_on)
		
func _ready_button_toggled(toggled_on: bool):
	readiness_updated.emit(toggled_on)
