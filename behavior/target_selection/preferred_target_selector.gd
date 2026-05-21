extends NodeTargetSelector

# Returns the actor's committed preferred target (see BehaviorComponent), or no
# target at all when the slot is empty — so rules using this selector are
# skipped while the character has no commitment, and fall through to the
# normal behavior.

func select_targets(_action: Action, actor: Actor, _side_component: SideComponent) -> Array[Actor]:
	var targets: Array[Actor] = []
	var bc := BehaviorComponent.get_or_null(actor)
	if bc and bc.preferred_target and is_instance_valid(bc.preferred_target):
		targets.append(bc.preferred_target)
	return targets
