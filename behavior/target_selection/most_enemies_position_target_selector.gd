extends PositionTargetSelector

# Returns the position where the action's AoE shape would catch the most
# enemies (shared with the Can Hit Enemies condition via AoeTargetingHelper).
# Pairs with ranged AoE actions (e.g. Fireball) — for self-centered AoEs
# (e.g. Consecrate) use Target: Self instead, since the placement is fixed
# on the caster anyway.

func select_targets(action: Action, actor: Actor, side_component: SideComponent) -> Array[Vector2]:
	if not action or action.def.aoe_placement == ActionDef.AoePlacement.NONE:
		push_error("Most Enemies Position used with non-AoE action")
		return []
	var placement := AoeTargetingHelper.best_placement(actor, action, side_component)
	if not placement.valid:
		return []
	return [placement.transform.origin]
