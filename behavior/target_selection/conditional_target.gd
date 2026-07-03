extends Target

class_name ConditionalTarget

# Stored ANDed condition evaluators that get re-checked via
# meets_condition() while the action is in progress.
var condition_evaluators: Array = []

## Whether the target still meets all initial conditions.
func meets_condition() -> bool:
	if not valid():
		return false
	if condition_evaluators.is_empty():
		return true
	match type:
		Type.ACTOR:
			for ev in condition_evaluators:
				var actor_eval = ev as TargetActorConditionEvaluator
				assert(actor_eval, "Actor target unexpectedly got wrong evaluator type")
				if not actor_eval.evaluate(actor):
					return false
			return true
		Type.POSITION:
			for ev in condition_evaluators:
				var pos_eval = ev as PositionConditionEvaluator
				assert(pos_eval, "Position target unexpectedly got wrong evaluator type")
				if not pos_eval.evaluate(pos):
					return false
			return true
		Type.ACTORS:
			assert(false, "Implement me when there are Actors targets")
	return false

static func make_actor_conditional_target(actor_: Actor, evaluators: Array[TargetActorConditionEvaluator]) -> ConditionalTarget:
	var target = ConditionalTarget.new()
	target.type = Type.ACTOR
	target.actor = actor_
	target.condition_evaluators = evaluators
	return target

static func make_self_conditional_target(actor_: Actor, evaluators: Array[TargetActorConditionEvaluator]) -> ConditionalTarget:
	var target = ConditionalTarget.new()
	target.type = Type.SELF
	target.actor = actor_
	target.condition_evaluators = evaluators
	return target

# Implement
static func make_actors_conditional_target(_actors: Array[Actor]) -> ConditionalTarget:
	return null

static func make_position_conditional_target(position: Vector2, evaluators: Array[PositionConditionEvaluator]) -> ConditionalTarget:
	var target = ConditionalTarget.new()
	target.type = Type.POSITION
	target.pos = position
	target.condition_evaluators = evaluators
	return target
