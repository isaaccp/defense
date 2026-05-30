extends FloatTargetActorConditionEvaluator

# Distance from a candidate enemy to the nearest tower. Pairs naturally with
# Set Preferred Target — gating commitment on "an enemy has gotten close to
# the objective" rather than "an enemy is slightly closer to the tower than
# any other (right now)". If there are no towers, returns 0 so the condition
# is effectively a no-op against ">=" thresholds.

func get_value(target: Actor) -> float:
	var towers := Global.get_tree().get_nodes_in_group(Groups.TOWERS)
	if towers.is_empty():
		return 0.0
	var nearest: float = INF
	for t in towers:
		var d: float = (t as Node2D).global_position.distance_to(target.global_position)
		if d < nearest:
			nearest = d
	return nearest
