extends NodeTargetSelector

func select_target(action: Action, actor: Actor, side_component: SideComponent) -> Target:
	var evaluators: Array[TargetActorConditionEvaluator] = []
	for evaluator in condition_evaluators:
		evaluator.action = action
		evaluator.side_component = side_component
		if not evaluator.evaluate(actor):
			return Target.make_invalid()
		evaluators.append(evaluator)
	return ConditionalTarget.make_self_conditional_target(actor, evaluators)

func select_targets(_action: Action, actor: Actor, _side_component: SideComponent) -> Array[Actor]:
	return [actor]
