extends Area2D

class_name HurtboxComponent

const component = &"HurtboxComponent"

signal hurtbox_hit

@export_group("Required")
@export var side_component: SideComponent

@export_group("Optional")
@export var logging_component: LoggingComponent

# Optional as e.g. you may still want to have a hurtbox
# for things that can't be killed.
@export var health_component: HealthComponent

func can_handle_collision():
	return (not health_component) or health_component.health > 0

func handle_collision(owner_name: String, hitbox_name: String, damage: int):
	hurtbox_hit.emit()
	_log("Hit by %s's %s for %d damage" % [owner_name, hitbox_name, damage])
	if health_component:
		health_component.damage(damage)

func _log(message: String):
	if not logging_component:
		return
	logging_component.add_log_entry(LoggingComponent.LogType.HURT, message)
