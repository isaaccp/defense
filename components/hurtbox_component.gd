extends Area2D

class_name HurtboxComponent

const component = &"HurtboxComponent"

signal hurtbox_hit

@export_group("Required")
@export var side_component: SideComponent

@export_group("Optional")
@export var logging_component: LoggingComponent

# Optional as e.g. you may still want to have a hurtbox
# for things that can't be killed. Same for status.
@export var health_component: HealthComponent
@export var status_component: StatusComponent

func can_handle_collision():
	if not (health_component or status_component):
		return false
	if health_component and health_component.is_dead:
		return false
	return true

func handle_collision(owner_name: String, hitbox_name: String, hit_effect: HitEffect):
	hurtbox_hit.emit()
	_log("%s's %s %s" % [owner_name, hitbox_name, hit_effect.log_text()])
	if health_component:
		var adjusted_damage = hit_effect.adjusted_damage()
		# TODO: Further adjusting depending on e.g. armor, etc.
		if adjusted_damage != 0:
			health_component.damage(adjusted_damage)
	if status_component:
		if hit_effect.status != StatusDef.Id.UNSPECIFIED:
			# TODO: Check for protection and what not.
			status_component.set_status(hit_effect.action, hit_effect.status, hit_effect.status_duration)

func _log(message: String):
	if not logging_component:
		return
	logging_component.add_log_entry(LoggingComponent.LogType.HURT, message)
