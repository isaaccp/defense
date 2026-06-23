extends Action

const smite_scene = preload("res://behavior/actions/scenes/smite.tscn")

var smite: ActionScene
var attack_dir: Vector2

func _init():
	max_distance = 250
	prepare_time = 0.2
	focus_cost = 2
	cooldown = 4.0

func post_prepare():
	if target and target.valid() and target.type == Target.Type.ACTOR:
		var target_actor = target.actor
		smite = smite_scene.instantiate() as ActionScene
		_initialize_action_scene(smite)
		action_sprites.add_child(smite)
		smite.global_position = target_actor.global_position
	
	action_finished()

func description():
	return "Calls down holy light on a single target, dealing 8 holy damage."
