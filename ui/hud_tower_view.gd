extends Control

class_name HudTowerView
	
func initialize(tower: Node2D) -> void:
	var health = Component.get_health_component_or_die(tower)
	health.health_updated.connect(_on_health_updated)
	%Title.text = tower.name

func _on_health_updated(health_update: HealthComponent.HealthUpdate):
	%HealthBar.max_value = health_update.max_health
	%HealthBar.value = health_update.health
	%HealthLabel.text = "%d / %d" % [health_update.health, health_update.max_health]
