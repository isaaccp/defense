@tool
extends Polygon2D

class_name PlacementZone

# A polygonal region where the player may place characters during PREPARE.
# Polygon vertices are authored in the editor in local coordinates.

func _ready():
	if Engine.is_editor_hint():
		return
	# Hidden by default; the level toggles visibility during PREPARE.
	visible = false
	if color.a == 1.0:
		color = Color(0.2, 0.6, 0.9, 0.25)

func contains(world_point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(to_local(world_point), polygon)

# Returns the point on the polygon boundary nearest to world_point, in world coordinates.
func closest_edge_point(world_point: Vector2) -> Vector2:
	var local = to_local(world_point)
	var best := Vector2.INF
	var best_d := INF
	var n := polygon.size()
	for i in n:
		var a := polygon[i]
		var b := polygon[(i + 1) % n]
		var p := Geometry2D.get_closest_point_to_segment(local, a, b)
		var d := local.distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = p
	return to_global(best)
