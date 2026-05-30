extends Action

# Self-centered AoE that paralyzes nearby enemies briefly. AoE shape +
# placement are declared on the ActionDef (so the Can Hit Enemies condition
# can read them); the action just instantiates the scene and lets
# action_scene apply def.aoe_shape to the hitbox.

const consecrate_scene = preload("res://behavior/actions/scenes/consecrate.tscn")

var consecrate: ActionScene

func _init():
	prepare_time = 0.3
	cooldown = 4.0
	focus_cost = 6

func post_prepare():
	if not _after_await_check(false):
		return
	consecrate = consecrate_scene.instantiate() as ActionScene
	_initialize_action_scene(consecrate)
	action_sprites.add_child(consecrate)
	consecrate.global_position = actor.attack_position()
	Global.get_tree().create_timer(0.6, false).timeout.connect(action_finished)

func description():
	return "Channels holy light around the priest, paralyzing nearby enemies for 1.5 seconds."
