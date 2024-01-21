extends ConditionEvaluator

class_name TargetActorConditionEvaluator

var actor: Actor

func evaluate(_target: Actor) -> bool:
	assert(false, "Must be implemented")
	return false

static func make(condition: ConditionDef, actor: Actor) -> TargetActorConditionEvaluator:
	assert(not condition.abstract)
	if not condition.type in [ConditionDef.Type.TARGET_ACTOR, ConditionDef.Type.TARGET_POSITION]:
		return null
	var evaluator: TargetActorConditionEvaluator
	if condition.type == ConditionDef.Type.TARGET_ACTOR:
		evaluator = condition.evaluator_script.new() as TargetActorConditionEvaluator
	else:
		var position_evaluator = PositionConditionEvaluator.make(condition, actor)
		evaluator = PositionToActorConditionEvaluatorAdapter.new(position_evaluator)
	evaluator.def = condition
	evaluator.actor = actor
	return evaluator
