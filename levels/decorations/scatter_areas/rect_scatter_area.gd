@tool
extends ScatterArea

class_name RectScatterArea

@export var rect: Rect2 = Rect2(Vector2.ZERO, Vector2(200, 200))

func random_point(rng: RandomNumberGenerator) -> Vector2:
	return Vector2(
		rng.randf_range(rect.position.x, rect.end.x),
		rng.randf_range(rect.position.y, rect.end.y),
	)

func draw_boundary(canvas: CanvasItem) -> void:
	canvas.draw_rect(rect, BOUNDARY_COLOR, false, BOUNDARY_WIDTH)
