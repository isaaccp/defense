extends NodeTargetSelector

func select_targets(_action: Action, _actor: Actor, _side_component: SideComponent) -> Array[Actor]:
	var towers = Global.get_tree().get_nodes_in_group(Groups.TOWERS)
	var targets: Array[Actor] = []
	targets.assign(towers)
	return targets
