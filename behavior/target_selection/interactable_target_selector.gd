extends NodeTargetSelector

class_name InteractableTargetSelector

func select_targets(_action: Action, _actor: Actor, side_component: SideComponent) -> Array[Actor]:
	var wanted_kind := def.params.interactable_kind
	if wanted_kind == Interactable.Kind.UNSPECIFIED:
		return []
	var targets: Array[Actor] = []
	for node in side_component.interactables():
		var interactable := node as Interactable
		if not interactable:
			continue
		if interactable.opened:
			continue
		if interactable.kind != wanted_kind:
			continue
		targets.append(interactable)
	return targets
