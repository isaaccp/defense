extends TargetActorConditionEvaluator

class_name PositionToActorConditionEvaluatorAdapter

var evaluator: PositionConditionEvaluator

func _init(position_evaluator: PositionConditionEvaluator):
	evaluator = position_evaluator

func evaluate(target: Actor) -> bool:
	return evaluator.evaluate(target.position)
