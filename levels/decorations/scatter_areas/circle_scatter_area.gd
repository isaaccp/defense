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

func bounds() -> Rect2:
	return Rect2(center - Vector2(radius, radius), Vector2(radius, radius) * 2.0)

func contains(point: Vector2) -> bool:
	return center.distance_to(point) <= radius

func draw_boundary(canvas: CanvasItem) -> void:
	canvas.draw_arc(center, radius, 0.0, TAU, 64, BOUNDARY_COLOR, BOUNDARY_WIDTH)
