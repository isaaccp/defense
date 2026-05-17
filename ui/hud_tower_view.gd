extends Control

class_name HudTowerView

var tower: Node2D

# Refactor this with HudCharacterView.
func initialize(tower_: Node2D) -> void:
	tower = tower_
	var vitals = tower.get_component_or_die(VitalsComponent) as VitalsComponent
	vitals.vital_updated.connect(_on_vital_updated)
	# Set health to current value (in case we missed the signal setting initial health,
	# which happens when we play a level through F6). We only can do it if
	# we missed the signal, otherwise both updates happen in the same frame
	# and the progress bar seems confused.
	if vitals.get_vital_current(VitalsComponent.VitalType.HEALTH) > 0:
		_set_health(vitals.get_vital_current(VitalsComponent.VitalType.HEALTH),
					vitals.get_vital_max(VitalsComponent.VitalType.HEALTH))
	%Title.text = tower.name.capitalize()

func _set_health(health: int, max_health: int):
	# max_value before value: ProgressBar clamps value to the current max on
	# assignment, so setting value first while max is still the scene default
	# silently truncates it.
	%HealthBar.max_value = max_health
	%HealthBar.value = health
	%HealthLabel.text = "%d / %d" % [health, max_health]

func _on_vital_updated(vital_update: VitalsComponent.VitalUpdate):
	if vital_update.type != VitalsComponent.VitalType.HEALTH:
		return
	_set_health(vital_update.current_value, vital_update.max_value)
