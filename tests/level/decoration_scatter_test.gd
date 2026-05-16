extends GutTest

const tree_green = preload("res://levels/decorations/tree_green.tscn")

class TestBase extends GutTest:
	var scatter: DecorationScatter

	func before_each():
		scatter = DecorationScatter.new()
		add_child_autoqfree(scatter)
		scatter.decoration = tree_green
		scatter.rng_seed = 1

	func _rect_area(x: float, y: float, w: float, h: float) -> RectScatterArea:
		var a := RectScatterArea.new()
		a.rect = Rect2(x, y, w, h)
		return a

class TestRectArea extends TestBase:
	func before_each():
		super()
		scatter.area = _rect_area(0, 0, 200, 200)

	func test_count_matches_export():
		scatter.count = 12
		scatter.scatter()
		assert_eq(scatter.get_child_count(), 12)

	func test_positions_within_rect():
		scatter.count = 30
		scatter.scatter()
		var rect := (scatter.area as RectScatterArea).rect
		for child in scatter.get_children():
			assert_true(rect.has_point(child.position),
				"%s outside %s" % [child.position, rect])

	func test_deterministic_with_seed():
		scatter.count = 10
		scatter.scatter()
		var first: Array[Vector2] = []
		for child in scatter.get_children():
			first.append(child.position)
		scatter.scatter()
		var second: Array[Vector2] = []
		for child in scatter.get_children():
			second.append(child.position)
		assert_eq(first, second)

	func test_min_distance_respected():
		scatter.count = 8
		scatter.min_distance = 50.0
		scatter.scatter()
		var positions: Array[Vector2] = []
		for child in scatter.get_children():
			positions.append(child.position)
		for i in positions.size():
			for j in range(i + 1, positions.size()):
				assert_gte(positions[i].distance_to(positions[j]), 50.0)

	func test_no_decoration_scene_is_safe():
		scatter.decoration = null
		scatter.count = 5
		scatter.scatter()
		assert_eq(scatter.get_child_count(), 0)

	func test_no_area_is_safe():
		scatter.area = null
		scatter.count = 5
		scatter.scatter()
		assert_eq(scatter.get_child_count(), 0)

	func test_rescatter_clears_previous():
		scatter.count = 10
		scatter.scatter()
		assert_eq(scatter.get_child_count(), 10)
		scatter.count = 3
		scatter.scatter()
		assert_eq(scatter.get_child_count(), 3)

class TestCircleArea extends TestBase:
	func before_each():
		super()
		var a := CircleScatterArea.new()
		a.center = Vector2(100, 100)
		a.radius = 50.0
		scatter.area = a

	func test_positions_within_circle():
		scatter.count = 30
		scatter.scatter()
		var area := scatter.area as CircleScatterArea
		for child in scatter.get_children():
			assert_lte(child.position.distance_to(area.center), area.radius + 0.001)

class TestAnnulusArea extends TestBase:
	func before_each():
		super()
		var a := AnnulusScatterArea.new()
		a.center = Vector2(100, 100)
		a.inner_radius = 30.0
		a.outer_radius = 60.0
		scatter.area = a

	func test_positions_within_annulus():
		scatter.count = 50
		scatter.scatter()
		var area := scatter.area as AnnulusScatterArea
		for child in scatter.get_children():
			var d: float = child.position.distance_to(area.center)
			assert_between(d, area.inner_radius - 0.001, area.outer_radius + 0.001)
