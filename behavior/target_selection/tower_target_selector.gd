extends NodeTargetSelector

func select_targets(action: Action, actor: Actor, side_component: SideComponent) -> Array:
	var towers = Global.get_tree().get_nodes_in_group(Groups.TOWERS)
	if towers.is_empty():
		return []
	return towers
