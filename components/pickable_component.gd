@tool
extends Area2D

class_name PickableComponent

signal selected(actor: Actor)

const component = &"PickableComponent"

@export_group("Required")
# A CollisionShape2D to clone the shape from.
@export var collision_shape: CollisionShape2D

@onready var internal_collision_shape: CollisionShape2D = $CollisionShape2D

# TODO: Move to a single place if https://github.com/godotengine/godot-proposals/issues/6416 is implemented.
var running = false
var picker_hover = false
var is_paused: bool

func _ready():
	internal_collision_shape.position = collision_shape.position
	internal_collision_shape.shape = collision_shape.shape.duplicate(true)
	is_paused = get_tree().paused

func _process(_delta):
	if is_paused != get_tree().paused:
		is_paused = get_tree().paused
		queue_redraw()

func draw_picker():
	var shape: Shape2D = internal_collision_shape.shape
	if not shape is CircleShape2D:
		print("Unexpected enemy collision shape not CircleShape2D")
	var circle = shape as CircleShape2D
	draw_circle(Vector2.ZERO, circle.radius, Color.RED, false, 2)
	var color = Color.WHITE
	if picker_hover:
		color.a = 0.4
	else:
		color.a = 0.2
	draw_circle(Vector2.ZERO, circle.radius-0.2, color, true)

func _draw():
	if is_paused:
		draw_picker()

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int):
	var mouse_event = event as InputEventMouseButton
	if not mouse_event:
		return
	if mouse_event.button_index == 1:
		# Current status: works, but this selection is based on the collission
		# shape used for moving, so you have to click on the feet to highlight.
		# Maybe we need an extra collission shape just for this or otherwise
		# maybe when paused we draw the feet shapes somehow and highlight them
		# when over them, so you can easily see what's up.
		print("selected %s" % get_parent().actor_name)
		selected.emit(get_parent())

func run():
	if running:
		assert(false, "run() called twice on %s" % component)
	running = true

func _get_configuration_warnings():
	var warnings = PackedStringArray()
	# TODO
	return warnings

func _on_mouse_entered():
	picker_hover = true
	queue_redraw()

func _on_mouse_exited():
	picker_hover = false
	queue_redraw()
