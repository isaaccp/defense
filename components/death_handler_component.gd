extends Node2D

class_name DeathHandlerComponent


@export var health_component: HealthComponent
@export var animation_player: AnimationPlayer
@export var free_on_death: bool = true
@export var collision_shape: CollisionShape2D

func _ready():
	assert(is_instance_valid(health_component))
	health_component.died.connect(_on_died)

func _on_died():
	if collision_shape:
		collision_shape.disabled = true
	animation_player.play("death")
	await animation_player.animation_finished
	if free_on_death:
		get_parent().queue_free()
