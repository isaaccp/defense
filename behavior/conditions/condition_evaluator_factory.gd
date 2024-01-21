extends Object

class_name ConditionEvaluatorFactory

static func make_any_condition_evaluator(condition: ConditionDef) -> AnyConditionEvaluator:
	assert(not condition.abstract)
	var evaluator = condition.evaluator_script.new() as AnyConditionEvaluator
	evaluator.def = condition
	return evaluator

static func make_self_condition_evaluator(condition: ConditionDef, actor: Actor) -> SelfConditionEvaluator:
	assert(not condition.abstract)
	var evaluator = condition.evaluator_script.new() as SelfConditionEvaluator
	evaluator.def = condition
	evaluator.actor = actor
	return evaluator

static func make_position_condition_evaluator(condition: ConditionDef, actor: Actor) -> PositionConditionEvaluator:
	assert(not condition.abstract)
	if not condition.type in [ConditionDef.Type.TARGET_POSITION]:
		return null
	var evaluator = condition.evaluator_script.new() as PositionConditionEvaluator
	evaluator.def = condition
	evaluator.actor = actor
	return evaluator

static func make_target_actor_condition_evaluator(condition: ConditionDef, actor: Actor) -> TargetActorConditionEvaluator:
	assert(not condition.abstract)
	if not condition.type in [ConditionDef.Type.TARGET_ACTOR, ConditionDef.Type.TARGET_POSITION]:
		return null
	var evaluator: TargetActorConditionEvaluator
	if condition.type == ConditionDef.Type.TARGET_ACTOR:
		evaluator = condition.evaluator_script.new() as TargetActorConditionEvaluator
	else:
		var position_evaluator = ConditionEvaluatorFactory.make_position_condition_evaluator(condition, actor)
		evaluator = PositionToActorConditionEvaluatorAdapter.new(position_evaluator)
	evaluator.def = condition
	evaluator.actor = actor
	return evaluator
