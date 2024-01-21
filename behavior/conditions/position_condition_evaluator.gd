extends ConditionEvaluator

class_name PositionConditionEvaluator

var actor: Actor

func evaluate(_target: Vector2) -> bool:
	assert(false, "Must be implemented")
	return false

static func make(condition: ConditionDef, actor: Actor) -> PositionConditionEvaluator:
	assert(not condition.abstract)
	if not condition.type in [ConditionDef.Type.TARGET_POSITION]:
		return null
	var evaluator = condition.evaluator_script.new() as PositionConditionEvaluator
	evaluator.def = condition
	evaluator.actor = actor
	return evaluator
