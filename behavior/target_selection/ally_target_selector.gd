extends NodeTargetSelector

func select_targets(action: Action, body: CharacterBody2D, side_component: SideComponent) -> Array:
	var targets = side_component.allies()
	targets.erase(body)
	return targets
