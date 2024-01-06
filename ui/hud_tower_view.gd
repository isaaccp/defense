extends Control

class_name HudTowerView

var tower: Node2D

# Refactor this with HudCharacterView.
func initialize(tower_: Node2D) -> void:
	tower = tower_
	var health = Component.get_health_component_or_die(tower)
	health.health_updated.connect(_on_health_updated)
	# Set health to current value (in case we missed the signal setting initial health,
	# which happens when we play a level through F6). We only can do it if
	# we missed the signal, otherwise both updates happen in the same frame
	# and the progress bar seems confused.
	if health.health > 0:
		_set_health(health.health, health.max_health)
	%Title.text = tower.name.capitalize()

func _set_health(health: int, max_health: int):
	%HealthBar.value = health
	%HealthBar.max_value = max_health
	%HealthLabel.text = "%d / %d" % [health, max_health]

func _on_health_updated(health_update: HealthComponent.HealthUpdate):
	_set_health(health_update.health, health_update.max_health)
