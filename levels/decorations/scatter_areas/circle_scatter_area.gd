@tool
extends ScatterArea

class_name CircleScatterArea

@export var center: Vector2 = Vector2.ZERO
@export var radius: float = 100.0

func random_point(rng: RandomNumberGenerator) -> Vector2:
	# sqrt() on the radius factor yields uniform area distribution
	# (without it, points cluster near the center).
	var r := sqrt(rng.randf()) * radius
	var theta := rng.randf() * TAU
	return center + Vector2(cos(theta), sin(theta)) * r

func draw_boundary(canvas: CanvasItem) -> void:
	canvas.draw_arc(center, radius, 0.0, TAU, 64, BOUNDARY_COLOR, BOUNDARY_WIDTH)
