extends ConditionEvaluator

class_name SelfConditionEvaluator

var actor: Actor

func evaluate() -> bool:
	assert(false, "Must be implemented")
	return false

static func make(condition: ConditionDef, actor: Actor) -> SelfConditionEvaluator:
	assert(not condition.abstract)
	var evaluator = condition.evaluator_script.new() as SelfConditionEvaluator
	evaluator.def = condition
	evaluator.actor = actor
	return evaluator
