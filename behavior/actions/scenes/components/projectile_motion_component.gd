@tool
extends MotionComponentBase

class_name ProjectileMotionComponent

const component = &"ProjectileMotionComponent"

@export_group("Required")
## Initial projectile speed.
@export var speed: float
@export_group("Optional")
## Drag applied to projectile, as a fraction of current velocity.
@export var drag: float = 0.0
## Whether to seek target.
@export var homing: bool
## Provides target, required if homing is set.
@export var target_component: TargetComponent
## Steering force. How much force to apply when 'homing'.
@export var steering_force: float = 50.0

var velocity: Vector2
var steering_acceleration = Vector2.ZERO

var running = false

func run():
	if running:
		assert(false, "run() called twice on %s" % component)
	running = true
	if homing:
		assert(target_component, "homing was set but target was not provided")
		assert(target_component.target, "target_component didn't have a target")
		assert(target_component.target.type == Target.Type.ACTOR)
		# Target may become invalid later, but it must be valid on run.
		assert(target_component.target.valid())
	velocity = global_transform.x * speed

func steer_force() -> Vector2:
	var desired = (target_component.target.position() - global_position).normalized() * speed
	return (desired - velocity).normalized() * steering_force

func _physics_process(delta: float):
	if not running or done:
		return
	var steer = Vector2.ZERO
	## If target is no longer valid, mark done and return.
	## Should later signal for some animation.
	if homing:
		if not target_component.target.valid():
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

static func get_or_null(node: Node) -> ProjectileMotionComponent:
	return Component.get_or_null(node, component) as ProjectileMotionComponent

static func get_or_die(node: Node) -> ProjectileMotionComponent:
	var component = get_or_null(node)
	assert(component)
	return component
