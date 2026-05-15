extends Node2D

class_name PlacementComponent

# Container of one or more PlacementZone children defining where the player
# may place characters during PREPARE. Stages may override the default
# whole-map zone by replacing or adding PlacementZone children.

const component = &"PlacementComponent"

func zones() -> Array[PlacementZone]:
	var out: Array[PlacementZone] = []
	for child in get_children():
		if child is PlacementZone:
			out.append(child)
	return out

func contains(world_point: Vector2) -> bool:
	for zone in zones():
		if zone.contains(world_point):
			return true
	return false

# Returns world_point unchanged if inside any zone, otherwise the closest point
# on any zone boundary.
func closest_valid_point(world_point: Vector2) -> Vector2:
	if contains(world_point):
		return world_point
	var best := Vector2.INF
	var best_d := INF
	for zone in zones():
		var p := zone.closest_edge_point(world_point)
		var d := world_point.distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = p
	return best

func set_zones_visible(visible_: bool) -> void:
	for zone in zones():
		zone.visible = visible_
