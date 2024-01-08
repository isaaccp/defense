extends NodeTargetSelector

func select_targets(_action: Action, _actor: Actor, side_component: SideComponent) -> Array:
	return side_component.enemies()
