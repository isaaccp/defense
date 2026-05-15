extends GutTest

# Two disjoint square zones:
#   Zone A: (0,0)-(100,100)
#   Zone B: (200,0)-(300,100)
class TestDisjointZones extends GutTest:
	var component: PlacementComponent

	func before_each():
		component = PlacementComponent.new()
		add_child_autoqfree(component)
		component.add_child(_make_zone(PackedVector2Array([
			Vector2(0, 0), Vector2(100, 0), Vector2(100, 100), Vector2(0, 100),
		])))
		component.add_child(_make_zone(PackedVector2Array([
			Vector2(200, 0), Vector2(300, 0), Vector2(300, 100), Vector2(200, 100),
		])))

	func _make_zone(poly: PackedVector2Array) -> PlacementZone:
		var zone := PlacementZone.new()
		zone.polygon = poly
		return zone

	func test_contains_inside_first_zone():
		assert_true(component.contains(Vector2(50, 50)))

	func test_contains_inside_second_zone():
		assert_true(component.contains(Vector2(250, 50)))

	func test_contains_in_gap_between_zones():
		assert_false(component.contains(Vector2(150, 50)))

	func test_contains_outside_all_zones():
		assert_false(component.contains(Vector2(-10, -10)))
		assert_false(component.contains(Vector2(400, 400)))

	func test_closest_valid_point_inside_returns_input():
		var p := Vector2(50, 50)
		assert_eq(component.closest_valid_point(p), p)

	func test_closest_valid_point_clamps_to_nearest_edge():
		# (50, -20) is just above zone A's top edge -> clamp to (50, 0).
		assert_eq(component.closest_valid_point(Vector2(50, -20)), Vector2(50, 0))

	func test_closest_valid_point_picks_nearest_zone():
		# (180, 50) is in the gap, 80 from zone A's right edge, 20 from zone B's
		# left edge -> snap to zone B.
		assert_eq(component.closest_valid_point(Vector2(180, 50)), Vector2(200, 50))

	func test_closest_valid_point_respects_zone_transform():
		# Move zone B by +(0, 500). Its world polygon is now (200,500)-(300,600).
		var b := component.zones()[1]
		b.position = Vector2(0, 500)
		# A point inside the original (untranslated) polygon should now be outside,
		# and a point inside the translated polygon should be inside.
		assert_false(component.contains(Vector2(250, 50)))
		assert_true(component.contains(Vector2(250, 550)))
