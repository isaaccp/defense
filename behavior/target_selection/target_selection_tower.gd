extends Object

static func select_target(body: CharacterBody2D, side_component: SideComponent, action: Action, target_selection_def: TargetSelectionDef) -> Target:
	var towers = Global.get_tree().get_nodes_in_group(Groups.TOWERS)
	if towers.is_empty():
		return null
	assert(towers.size() == 1)
	var tower = towers[0]
	var max_distance_squared = action.max_distance * action.max_distance
	var min_distance_squared = action.min_distance * action.min_distance
	var distance_squared = tower.position.distance_squared_to(body.position)
	if min_distance_squared < distance_squared and distance_squared < max_distance_squared:
		return Target.make_node_target(towers[0])
	return Target.make_invalid()
