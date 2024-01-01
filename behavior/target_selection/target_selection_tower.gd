extends Object

static func select_target(body: CharacterBody2D, side_component: SideComponent, action: Action, target_selection_def: TargetSelectionDef) -> Target:
	var towers = Global.get_tree().get_nodes_in_group(Groups.TOWERS)
	if towers.is_empty():
		return null
	assert(towers.size() == 1)
	return Target.make_node_target(towers[0])
