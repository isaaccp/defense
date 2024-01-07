extends PositionTargetSelector

func select_targets(action: Action, actor: Actor, side_component: SideComponent) -> Array[Vector2]:
	var center = Global.subviewport.get_visible_rect().size / 2.0
	return [center]
