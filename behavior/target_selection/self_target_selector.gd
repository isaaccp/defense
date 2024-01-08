extends NodeTargetSelector

func select_targets(_action: Action, actor: Actor, _side_component: SideComponent) -> Array[Actor]:
	return [actor]
