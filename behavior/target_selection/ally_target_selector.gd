extends NodeTargetSelector

func select_targets(action: Action, actor: Actor, side_component: SideComponent) -> Array:
	var targets = side_component.allies()
	targets.erase(actor)
	return targets
