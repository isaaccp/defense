extends IntTargetActorConditionEvaluator

# Counts how many of the actor's enemies are currently targeting the given
# candidate (which can be self, ally, or anything). Pairs naturally with
# defensive abilities — buff/heal when an ally is about to be ganged up on.
# Predictive: fires as soon as enemies pick the target, before damage lands.

func get_value(target: Actor) -> int:
	if not side_component:
		get_value_failed = true
		return 0
	var count := 0
	for e in side_component.enemies():
		if not is_instance_valid(e) or (e as Actor).destroyed:
			continue
		var bc := BehaviorComponent.get_or_null(e) as BehaviorComponent
		if not bc or not bc.target or not bc.target.valid():
			continue
		if bc.target.type != Target.Type.ACTOR:
			continue
		if bc.target.actor == target:
			count += 1
	return count
