extends PositionTargetSorter

# Sorts positions by distance to the TOWER, not to the targeting actor — so
# "closest" means "the enemy that has advanced furthest toward the objective."
# A character using this sort holds the tower's front line and prioritises
# near-tower threats (including flank pockets) instead of chasing whatever
# enemy is nearest itself. If no tower exists it falls back to distance from
# the actor, behaving like Closest First.

var _reference: Vector2

func sort(this_actor: Actor, positions: Array[Vector2]) -> void:
	_reference = _tower_position(this_actor)
	positions.sort_custom(compare.bind(this_actor))

func compare(pos_a: Vector2, pos_b: Vector2, _this_actor: Actor) -> bool:
	return _reference.distance_to(pos_a) < _reference.distance_to(pos_b)

func _tower_position(this_actor: Actor) -> Vector2:
	var towers := Global.get_tree().get_nodes_in_group(Groups.TOWERS)
	if towers.is_empty():
		return this_actor.global_position
	return (towers[0] as Node2D).global_position
