extends NodeTargetSelector

func select_targets(_action: Action, _actor: Actor, side_component: SideComponent) -> Array[Actor]:
	var targets: Array[Actor] = []
	targets.assign(side_component.allies())
	return targets
