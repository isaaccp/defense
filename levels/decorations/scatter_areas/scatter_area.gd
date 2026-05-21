@tool
extends Resource

class_name ScatterArea

const BOUNDARY_COLOR := Color(0.4, 0.9, 1.0, 0.8)
const BOUNDARY_WIDTH := 2.0

# Abstract base for shapes used by DecorationScatter. Subclasses pick a
# uniformly-random point inside the shape (in the scatter node's local frame).
# Add new shapes (annulus, polygon, etc.) by extending this and overriding
# random_point().

func random_point(_rng: RandomNumberGenerator) -> Vector2:
	push_error("ScatterArea.random_point() not implemented by %s" % get_class())
	return Vector2.ZERO

# Axis-aligned bounding box of the shape. Used by jittered-grid placement.
func bounds() -> Rect2:
	push_error("ScatterArea.bounds() not implemented by %s" % get_class())
	return Rect2()

# Whether a point lies inside the shape.
func contains(_point: Vector2) -> bool:
	push_error("ScatterArea.contains() not implemented by %s" % get_class())
	return false

# Draws the area's boundary in the editor for visual feedback. Subclasses
# override to render their shape; canvas is a CanvasItem (typically the
# DecorationScatter node) in whose local space the area is defined.
func draw_boundary(_canvas: CanvasItem) -> void:
	pass
