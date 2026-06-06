extends Object

class_name TargetSelectorFactory

static func make_actor_target_selector(target: TargetSelectionDef, target_actor_evaluators: Array[TargetActorConditionEvaluator]) -> NodeTargetSelector:
	assert(target.type == Target.Type.ACTOR || target.type == Target.Type.SELF)
	var selector = target.selector_script.new() as NodeTargetSelector
	selector.def = target
	selector.condition_evaluators = target_actor_evaluators
	return selector

static func make_position_target_selector(target: TargetSelectionDef, target_position_evaluators: Array[PositionConditionEvaluator]) -> PositionTargetSelector:
	assert(target.type == Target.Type.POSITION)
	var selector = target.selector_script.new() as PositionTargetSelector
	selector.def = target
	selector.condition_evaluators = target_position_evaluators
	return selector
