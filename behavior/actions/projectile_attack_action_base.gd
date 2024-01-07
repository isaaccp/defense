extends Action

class_name ProjectileAttackActionBase

var projectile_scene: PackedScene
var last_target_pos: Vector2
# Could provide more stuff here, e.g. multiple shots, wait times before/after,
# etc. For now keep it simple.

func _init():
	super()

func spawn_projectile():
	assert(projectile_scene, "Must be provided in subclass")
	# So in multi-projectile subclasses it keeps firing at last position
	# rather than stopping. Could be made configurable.
	if target.valid():
		last_target_pos = target.position()
	var dir = (last_target_pos - body.position).normalized()
	var projectile = projectile_scene.instantiate() as ActionScene
	_initialize_action_scene(projectile)
	projectile.look_at(projectile.position + dir)
	projectile.position += dir * 35
	action_sprites.add_child(projectile)

func description() -> String:
	assert(false, "Must be implemented in subclass")
	return "Fires a projectile at a target"
