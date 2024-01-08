extends NodeTargetSelector

func select_targets(_action: Action, _actor: Actor, _side_component: SideComponent) -> Array:
	var towers = Global.get_tree().get_nodes_in_group(Groups.TOWERS)
	if towers.is_empty():
		return []
	return towers
