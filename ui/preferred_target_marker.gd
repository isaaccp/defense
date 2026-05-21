extends Node2D

# Floating marker placed on an enemy that a character has committed to as its
# preferred target. Purely cosmetic — its lifecycle is owned by the committing
# character's BehaviorComponent, which spawns and frees it.

const COLOR := Color(1.0, 0.78, 0.25)
const OUTLINE := Color(0.12, 0.08, 0.0, 0.9)
const BASE_Y := -30.0
const BOB := 3.0
const BOB_SPEED := 3.0

var _t := 0.0

func _ready() -> void:
	# Draw on top of the y-sorted level regardless of the enemy's depth.
	z_as_relative = false
	z_index = 50

func _process(delta: float) -> void:
	_t += delta
	position.y = BASE_Y - BOB * (0.5 + 0.5 * sin(_t * BOB_SPEED))

func _draw() -> void:
	# Downward-pointing arrowhead.
	var tri := PackedVector2Array([Vector2(-6, -7), Vector2(6, -7), Vector2(0, 4)])
	draw_colored_polygon(tri, COLOR)
	var outline := PackedVector2Array([tri[0], tri[1], tri[2], tri[0]])
	draw_polyline(outline, OUTLINE, 1.5)
