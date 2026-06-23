extends Action

# Ranged AoE: drops a sphere at the targeted position, dealing 3 frost damage
# and applying Slowed (-50% speed, 3s) to everything in radius. Damage is
# intentionally low — it's a setup spell that turns enemies into one-shot
# fodder for follow-up rules (e.g. Seeking Bolt picks off slowed grunts).

const chilling_sphere_scene = preload("res://behavior/actions/scenes/chilling_sphere.tscn")

var sphere: ActionScene

func _init():
	min_distance = 100
	max_distance = 300
	prepare_time = 0.3
	cooldown = 4.0
	focus_cost = 3

func post_prepare():
	if not _after_await_check(true):
		return
	sphere = chilling_sphere_scene.instantiate() as ActionScene
	_initialize_action_scene(sphere)
	action_sprites.add_child(sphere)
	# Position-targeted: drop the sphere at the target position itself.
	sphere.global_position = target_position()
	Global.get_tree().create_timer(0.6, false).timeout.connect(action_finished)

func description() -> String:
	return "Drops a chilling sphere at a position, dealing 3 frost damage and slowing enemies in the area (Slowed, -50% speed for 3s)."
