extends Target

class_name ConditionalTarget

# Populated by factory methods, needs to match target Type.
var condition_evaluator: ConditionEvaluator

## Whether the target still meets the initial condition.
func meets_condition() -> bool:
	if not condition_evaluator:
		return true
	match type:
		Type.ACTOR:
			var actor_condition_evaluator = condition_evaluator as TargetActorConditionEvaluator
			assert(actor_condition_evaluator, "Actor target unexpectedly got wrong evaluator type")
			return actor_condition_evaluator.evaluate(actor)
		Type.POSITION:
			var position_condition_evaluator = condition_evaluator as PositionConditionEvaluator
			assert(position_condition_evaluator, "Position target unexpectedly got wrong evaluator type")
			return position_condition_evaluator.evaluate(pos)
		Type.ACTORS:
			assert(false, "Implement me when there are Actors targets")
	return false

static func make_actor_conditional_target(actor_: Actor, condition_evaluator: TargetActorConditionEvaluator) -> ConditionalTarget:
	var target = ConditionalTarget.new()
	target.type = Type.ACTOR
	target.actor = actor_
	target.condition_evaluator = condition_evaluator
	return target

# Implement
static func make_actors_conditional_target(_actors: Array[Actor]) -> ConditionalTarget:
	return null

static func make_position_conditional_target(position: Vector2, condition_evaluator: PositionConditionEvaluator) -> ConditionalTarget:
	var target = ConditionalTarget.new()
	target.type = Type.POSITION
	target.pos = position
	target.condition_evaluator = condition_evaluator
	return target
