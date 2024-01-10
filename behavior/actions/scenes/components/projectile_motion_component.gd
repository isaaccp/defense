@tool
extends MotionComponentBase

class_name ProjectileMotionComponent

const component = &"ProjectileMotionComponent"

@export_group("Required")
## Initial projectile speed.
@export var speed: float
## Drag applied to projectile.
@export var drag: float
## If current velocity vector length divided by speed is less than this,
## consider move done.
@export var min_speed_fraction: float
## Whether to seek target.
@export var homing: bool
## Steering force. How much force to apply when 'homing'.
@export var steering_force: float = 50.0

var target: Target
var velocity: Vector2
var steering_acceleration = Vector2.ZERO

var running = false

func run():
	if running:
		assert(false, "run() called twice on %s" % component)
	running = true
	if homing:
		assert(target, "homing was set but target was not provided")
		assert(target.type == Target.Type.ACTOR)
		# Target may become invalid later, but it must be valid on run.
		assert(target.valid())
	velocity = global_transform.x * speed

func steer_force() -> Vector2:
	var desired = (target.position() - global_position).normalized() * speed
	return (desired - velocity).normalized() * steering_force

func _physics_process(delta: float):
	if not running or done:
		return
	var steer = Vector2.ZERO
	## If target is no longer valid, mark done and return.
	## Should later signal for some animation.
	if homing:
		if not target.valid():
			mark_done()
			return
		steer = steer_force()
	steering_acceleration += steer
	var drag_acceleration = -velocity * drag
	var acceleration = steering_acceleration + drag_acceleration
	velocity += acceleration * delta
	velocity = velocity.limit_length(speed)
	action_scene.global_rotation = velocity.angle()
	action_scene.global_position += velocity * delta

	if velocity.length()/speed < min_speed_fraction:
		mark_done()

static func get_or_null(node: Node) -> ProjectileMotionComponent:
	return Component.get_or_null(node, component) as ProjectileMotionComponent

static func get_or_die(node: Node) -> ProjectileMotionComponent:
	var component = get_or_null(node)
	assert(component)
	return component
