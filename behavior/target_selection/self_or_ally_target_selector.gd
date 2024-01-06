extends NodeTargetSelector

func select_targets(action: Action, actor: Actor, side_component: SideComponent) -> Array:
	return side_component.allies()
