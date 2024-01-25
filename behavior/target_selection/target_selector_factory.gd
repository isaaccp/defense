extends Object

class_name TargetSelectorFactory

static func make_actor_target_selector(target: TargetSelectionDef, target_actor_evaluator: TargetActorConditionEvaluator) -> NodeTargetSelector:
	assert(target.type == Target.Type.ACTOR)
	var selector = target.selector_script.new() as NodeTargetSelector
	selector.def = target
	selector.condition_evaluator = target_actor_evaluator
	return selector

static func make_position_target_selector(target: TargetSelectionDef, target_position_evaluator: PositionConditionEvaluator) -> PositionTargetSelector:
	assert(target.type == Target.Type.POSITION)
	var selector = target.selector_script.new() as PositionTargetSelector
	selector.def = target
	selector.condition_evaluator = target_position_evaluator
	return selector

