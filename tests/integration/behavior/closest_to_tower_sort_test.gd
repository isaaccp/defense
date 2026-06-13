extends GutTest

# Verifies the "Closest To Tower First" target sort orders positions by
# distance to a node in the TOWERS group — not to the targeting actor.

const sorter_script = preload("res://behavior/target_sort/closest_to_tower_first_position_target_sorter.gd")

func test_sorts_by_distance_to_tower():
	var tower := Node2D.new()
	tower.add_to_group(Groups.TOWERS)
	add_child_autoqfree(tower)
	tower.position = Vector2(100, 100)

	var sorter = sorter_script.new()
	# Listed worst-first; the sort must reorder them nearest-the-tower-first.
	var positions: Array[Vector2] = [
		Vector2(500, 100),  # dist 400 from tower
		Vector2(150, 100),  # dist 50
		Vector2(300, 100),  # dist 200
	]
	# this_actor is unused when a tower exists, so null is fine here.
	sorter.sort(null, positions)
	assert_eq(positions[0], Vector2(150, 100), "nearest the tower first")
	assert_eq(positions[1], Vector2(300, 100))
	assert_eq(positions[2], Vector2(500, 100), "farthest from the tower last")
