extends NodeTargetSelector

func select_targets(_action: Action, actor: Actor, side_component: SideComponent) -> Array[Actor]:
	var targets: Array[Actor] = []
	targets.assign(side_component.allies())
	targets.erase(actor)
	return targets
