extends Node2D

class_name DeathHandlerComponent

const component: StringName = &"DeathHandlerComponent"

@export var vitals_component: VitalsComponent
@export var animation_component: AnimationComponent
@export var free_on_death: bool = true
@export var collision_shape: CollisionShape2D

@export_group("Optional")
@export var logging_component: LoggingComponent

signal died

func _ready():
	if not is_instance_valid(vitals_component):
		push_error("DeathHandlerComponent requires vitals_component on '%s'" % get_parent().name)
		return
	vitals_component.vital_depleted.connect(_on_vital_depleted)

func _on_vital_depleted(vital_type: VitalsComponent.VitalType):
	if vital_type != VitalsComponent.VitalType.HEALTH:
		return
	_log_death()
	died.emit()
	_on_death.call_deferred()

func _log_death():
	if not logging_component:
		return
	var actor := get_parent()
	logging_component.add_log_entry(
		LoggingComponent.LogType.DEATH,
		"died @(%d, %d)" % [actor.position.x, actor.position.y],
	)
	
func _on_death():
	if collision_shape:
		collision_shape.disabled = true
	if animation_component:
		await animation_component.play_animation("death")
	# TODO: Use AutoFreeComponent.
	if free_on_death:
		get_parent().queue_free()
