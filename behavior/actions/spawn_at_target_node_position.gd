extends Action

class_name SpawnAtTargetNodePositionAction

# Must be set on _init().
var spawn_scene: PackedScene
# Time to wait to finish the action after spawning the action scene.
# Note this is in addition to the prepare_time.
var duration: float = -1.0

# Can be used in post_spawn.
var spawned: ActionScene

func spawn_and_wait():
	spawned = spawn_scene.instantiate() as ActionScene
	_initialize_action_scene(spawned)
	action_sprites.add_child(spawned)
	spawned.global_position = target_position(Target.PositionType.HURTBOX)
	post_spawn()
	Global.get_tree().create_timer(duration, false).timeout.connect(action_finished)

func post_spawn():
	pass

func post_initialize():
	assert(spawn_scene)
	assert(duration > 0)

func post_prepare():
	spawn_and_wait()
