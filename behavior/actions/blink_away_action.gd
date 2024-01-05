extends Action

const blink_away_fade_out_scene = preload("res://behavior/actions/scenes/blink_away_fade_out.tscn")
const blink_distance = 100

var sprite: Sprite2D
var prev_modulate: Color = Color.WHITE
var blink_out: ActionScene

func _init():
	cooldown = 3.0

func post_initialize():
	sprite = body.get_node("Sprite2D")
	prev_modulate = sprite.modulate
	_start_blink.call_deferred()

func _start_blink():
	blink_out = blink_away_fade_out_scene.instantiate() as ActionScene
	_initialize_action_scene(blink_out)
	action_sprites.add_child(blink_out)
	print(blink_out.animation_player.current_animation_length)
	# TODO: Do something fancier here, possibly some
	# AnimationComponent that can handle this (e.g.
	# get_animation_component().fade_out()
	# and that could use custom animations per character.
	var tween = body.create_tween()
	tween.tween_property(sprite, "modulate:a", 0, blink_out.animation_player.current_animation_length)
	await tween.finished
	# After awaiting, check if we were aborted.
	if finished:
		# Nothing to clean up, as clean up should already have
		# happened when action_finished() was called.
		return
	# Blink away from enemy.
	if not target.valid():
		action_finished()
		return
	var away_from = target.node.global_position
	var dir = away_from.direction_to(body.global_position)
	body.global_position += dir * blink_distance
	tween = body.create_tween()
	tween.tween_property(sprite, "modulate:a", 1, 0.4)
	await tween.finished
	action_finished()

func action_finished():
	super()
	# In case we are aborted before blink out.
	if is_instance_valid(blink_out):
		blink_out.queue_free()
	# Restore sprite modulate in case we were aborted.
	if is_instance_valid(sprite):
		sprite.modulate = prev_modulate
