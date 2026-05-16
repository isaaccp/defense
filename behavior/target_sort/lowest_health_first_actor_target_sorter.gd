extends ActorTargetSorter

# Sorts actors so the one with the lowest current HP comes first.
# Useful for "finish off the wounded enemy" / "heal the most-damaged ally"
# patterns. Actors without a VitalsComponent or HEALTH vital sort to the end.

func compare(actor_a: Actor, actor_b: Actor, _this_actor: Actor) -> bool:
	return _hp(actor_a) < _hp(actor_b)

func _hp(actor: Actor) -> float:
	var v: VitalsComponent = Component.get_or_null(actor, VitalsComponent.component)
	if not v:
		return INF
	return v.get_vital_current(VitalsComponent.VitalType.HEALTH)
