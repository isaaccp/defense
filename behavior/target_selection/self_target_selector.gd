extends NodeTargetSelector

func select_targets(action: Action, body: CharacterBody2D, side_component: SideComponent) -> Array:
	return [body]
