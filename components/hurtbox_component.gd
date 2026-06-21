@tool
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
@export var damage_component: DamageComponent
@export var status_component: StatusComponent
# Used to fire ON_DAMAGE_TAKEN effect hooks (e.g. Defiance). Optional —
# towers and characters without relics don't need this wired.
@export var effect_actuator_component: EffectActuatorComponent

func _ready():
	var config = get_parent().config
	if config:
		var hurtbox_component_config = config.get("hurtbox_component_config") as HurtboxComponentConfig
		if hurtbox_component_config:
			$CollisionShape2D.shape = hurtbox_component_config.collision_shape
			var rect = hurtbox_component_config.collision_shape.get_rect()
			$CollisionShape2D.position.y = -rect.size.y / 2.0

func can_handle_collision():
	if not (status_component or damage_component):
		return false
	if get_parent().destroyed:
		return false
	return true

func handle_collision(owner_name: String, hitbox_name: String, hit_effect: HitEffect) -> HitResult:
	hit.emit(hit_effect)
	var hit_result: HitResult
	if damage_component:
		hit_result = damage_component.process_hit(hit_effect)
	else:
		hit_result = HitResult.new()
	if not hit_result:
		push_error("Unexpected lack of hit_result")
		return null
	if not hit_effect.status_on_damage_only or hit_result.damage != 0:
		if status_component:
			if hit_effect.status:
				# TODO: Check for protection and what not.
				status_component.set_status(hit_effect.action_name, hit_effect.status, hit_effect.status_params, hit_effect.status_duration)
				hit_result.status = hit_effect.status.name

	_log("%s's %s %s. Result: %s" % [owner_name, hitbox_name, hit_effect.log_text(), hit_result.log_text()])
	if effect_actuator_component and hit_result.damage > 0:
		effect_actuator_component.notify_damage_taken(hit_result.damage, owner_name)
	return hit_result

func get_target_position() -> Vector2:
	var shape = get_node_or_null("CollisionShape2D")
	if shape:
		return shape.global_position
	return global_position

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
