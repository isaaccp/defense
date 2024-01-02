@tool
extends Object

class_name ConditionManager

static var conditions = {
	ConditionDef.Id.ALWAYS: preload("res://behavior/conditions/condition_always.gd"),
}

static func make_any_condition_evaluator(condition: ConditionDef) -> AnyConditionEvaluator:
	assert(not condition.abstract)
	var evaluator = conditions[condition.id].new() as AnyConditionEvaluator
	evaluator.def = condition
	return evaluator

static func make_self_condition_evaluator(condition: ConditionDef, body: Node2D) -> SelfConditionEvaluator:
	assert(not condition.abstract)
	var evaluator = conditions[condition.id].new() as SelfConditionEvaluator
	evaluator.def = condition
	evaluator.body = body
	return evaluator

static func make_target_node_condition_evaluator(condition: ConditionDef) -> TargetNodeConditionEvaluator:
	assert(not condition.abstract)
	var evaluator = conditions[condition.id].new() as TargetNodeConditionEvaluator
	evaluator.def = condition
	return evaluator

static func all_conditions() -> Array[ConditionDef.Id]:
	var all: Array[ConditionDef.Id] = []
	for id in conditions.keys():
		all.append(id as ConditionDef.Id)
	return all
