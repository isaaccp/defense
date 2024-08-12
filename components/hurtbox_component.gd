extends Area2D

class_name HurtboxComponent

const component = &"HurtboxComponent"

signal hit(hit_effect: HitEffect)

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

func handle_collision(owner_name: String, hitbox_name: String, hit_effect: HitEffect) -> HitResult:
	hit.emit(hit_effect)
	var hit_result: HitResult
	if health_component:
		hit_result = health_component.process_hit(hit_effect)
	else:
		hit_result = HitResult.new()
	if not hit_effect.status_on_damage_only or hit_result.damage != 0:
		if status_component:
			if hit_effect.status:
				# TODO: Check for protection and what not.
				status_component.set_status(hit_effect.action_name, hit_effect.status, hit_effect.status_duration)
				hit_result.status = hit_effect.status.name

	_log("%s's %s %s. Result: %s" % [owner_name, hitbox_name, hit_effect.log_text(), hit_result.log_text()])
	return hit_result

func _log(message: String, tooltip: String = ""):
	if not logging_component:
		return
	logging_component.add_log_entry(LoggingComponent.LogType.HURT, message, tooltip)

static func get_or_null(node: Node) -> HurtboxComponent:
	return Component.get_or_null(node, component) as HurtboxComponent

static func get_or_die(node: Node) -> HurtboxComponent:
	var component = get_or_null(node)
	assert(component)
	return component
