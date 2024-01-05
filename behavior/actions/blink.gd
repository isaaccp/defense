extends Action

class_name BlinkAction

const blink_fade_out_scene = preload("res://behavior/actions/scenes/blink_fade_out.tscn")

# Must be overriden
var blink_distance = -1
# If you need a valid target in update_position(), set this to true.
# The action will be cancelled for you if the target died.
var need_valid_target = false
# Initial target position.
var initial_target_pos: Vector2

# Shouldn't be needed by subclasses.
var sprite: Sprite2D
var prev_modulate: Color = Color.WHITE
var blink_out: ActionScene



func post_initialize():
	assert(blink_distance > 0)
	assert(cooldown > 0)
	initial_target_pos = target.node.global_position
	sprite = body.get_node("Sprite2D")
	prev_modulate = sprite.modulate
	_start_blink.call_deferred()

func _start_blink():
	blink_out = blink_fade_out_scene.instantiate() as ActionScene
	_initialize_action_scene(blink_out)
	action_sprites.add_child(blink_out)
	# TODO: Do something fancier here, possibly some
	# AnimationComponent that can handle this (e.g.
	# get_animation_component().fade_out()
	# and that could use custom animations per character.
	var tween = body.create_tween()
	tween.tween_property(sprite, "modulate:a", 0, 0.3)
	await tween.finished
	if not _after_await_check(need_valid_target):
		return
	update_position()
	tween = body.create_tween()
	tween.tween_property(sprite, "modulate:a", 1, 0.7)
	await tween.finished
	action_finished()

func update_position():
	assert(false, "Implement")

func action_finished():
	super()
	# In case we are aborted before blink out.
	if is_instance_valid(blink_out):
		blink_out.queue_free()
	# Restore sprite modulate in case we were aborted.
	if is_instance_valid(sprite):
		sprite.modulate = prev_modulate
