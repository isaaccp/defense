extends Action

class_name SpawnAtTargetNodePositionAction

# Must be set on _init().
var spawn_scene: PackedScene
var duration: float = -1.0
# TODO: Provide a way to spawn with a delay, to reflect slow casting.

# Can be used in post_spawn.
var spawned: ActionScene

func spawn():
	spawned = spawn_scene.instantiate() as ActionScene
	_initialize_action_scene(spawned)
	action_sprites.add_child(spawned)
	spawned.global_position = target.position()
	post_spawn()

func post_spawn():
	pass

func post_initialize():
	assert(spawn_scene)
	assert(duration > 0)
	spawn()
	Global.get_tree().create_timer(duration, false).timeout.connect(action_finished)
