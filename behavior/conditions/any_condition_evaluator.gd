extends ConditionEvaluator

class_name AnyConditionEvaluator

func evaluate() -> bool:
	assert(false, "Must be implemented")
	return false

static func make(condition: ConditionDef) -> AnyConditionEvaluator:
	assert(not condition.abstract)
	var evaluator = condition.evaluator_script.new() as AnyConditionEvaluator
	evaluator.def = condition
	return evaluator
