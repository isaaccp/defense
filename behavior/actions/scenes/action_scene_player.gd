extends Node2D

@export var action_scene: PackedScene
@export var spawn_interval = 2.0

# TODO: Add a panel that shows the scenes exported variables, so you can
# easily change them around and see the effect without having to reload.
# TODO: Make it so things look the same size as in the real game (as of now
# they don't because of the viewport, maybe just load gameplay.tscn and a
# dummy level).
func _ready():
	_start_spawning.call_deferred()

func _start_spawning():
	while true:
		var instance = action_scene.instantiate() as ActionScene
		instance.initialize("test_owner", ActionDef.new(), null, null, null)
		%Center.add_child(instance)
		await get_tree().create_timer(spawn_interval).timeout
