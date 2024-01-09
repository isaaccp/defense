extends MotionComponentBase

class_name ProjectileMotionComponent

@export_group("Required")
## Initial projectile speed.
@export var speed: float
## Drag applied to projectile.
@export var drag: float
## If current velocity vector length divided by speed is less than this,
## consider move done.
@export var min_speed_fraction: float

var velocity: Vector2

func _ready():
	var dir = Vector2(cos(global_rotation), sin(global_rotation)).normalized()
	velocity = dir * speed

func _physics_process(delta: float):
	if done:
		return
	velocity = velocity.lerp(Vector2.ZERO, drag * delta)
	if velocity.length()/speed < min_speed_fraction:
		mark_done()
		return
	action_scene.global_position += velocity * delta
