@tool
extends ScatterArea

class_name AnnulusScatterArea

# Ring shape: useful for surrounding an open area with decorations.
# inner_radius = 0 degenerates to a disc (same as CircleScatterArea).

@export var center: Vector2 = Vector2.ZERO
@export var inner_radius: float = 50.0
@export var outer_radius: float = 100.0

func random_point(rng: RandomNumberGenerator) -> Vector2:
	# Inverse-CDF sampling for a uniform annulus: r = sqrt(u·(R²-r²) + r²).
	var r2 := rng.randf() * (outer_radius * outer_radius - inner_radius * inner_radius) + inner_radius * inner_radius
	var r := sqrt(r2)
	var theta := rng.randf() * TAU
	return center + Vector2(cos(theta), sin(theta)) * r

func bounds() -> Rect2:
	return Rect2(center - Vector2(outer_radius, outer_radius), Vector2(outer_radius, outer_radius) * 2.0)

func contains(point: Vector2) -> bool:
	var d := center.distance_to(point)
	return d >= inner_radius and d <= outer_radius

func draw_boundary(canvas: CanvasItem) -> void:
	canvas.draw_arc(center, inner_radius, 0.0, TAU, 64, BOUNDARY_COLOR, BOUNDARY_WIDTH)
	canvas.draw_arc(center, outer_radius, 0.0, TAU, 64, BOUNDARY_COLOR, BOUNDARY_WIDTH)
