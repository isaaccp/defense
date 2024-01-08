extends PositionTargetSelector

func select_targets(_action: Action, _actor: Actor, _side_component: SideComponent) -> Array[Vector2]:
	var center = Global.subviewport.get_visible_rect().size / 2.0
	return [center]
