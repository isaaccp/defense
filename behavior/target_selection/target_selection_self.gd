extends Object

static func select_target(body: CharacterBody2D, side_component: SideComponent, action: Action, target_selection_def: TargetSelectionDef) -> Target:
	return Target.make_node_target(body)
