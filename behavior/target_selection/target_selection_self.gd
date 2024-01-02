extends Object

static func select_target(target_selection_def: TargetSelectionDef, evaluator: TargetNodeConditionEvaluator, action: Action, body: CharacterBody2D, side_component: SideComponent) -> Target:
	if evaluator and not evaluator.evaluate(body):
		return null
	return Target.make_node_target(body)
