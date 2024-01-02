@tool
extends Object

class_name ConditionManager

static var conditions = {
	ConditionDef.Id.ALWAYS: preload("res://skill_tree/skills/general/always_condition.tres"),
}

static func lookup(id: ConditionDef.Id) -> ConditionDef:
	return conditions[id].condition_def

static func make_instance(id: ConditionDef.Id) -> ConditionDef:
	var condition = lookup(id)
	# TODO: For now assert this, later we may add support to
	# specify parameters and we can verify parameters match.
	assert(condition.type == ConditionDef.Type.ANY)
	condition.abstract = false
	return condition

static func make_any_condition_evaluator(condition: ConditionDef) -> AnyConditionEvaluator:
	assert(not condition.abstract)
	var evaluator = lookup(condition.id).condition_script.new() as AnyConditionEvaluator
	evaluator.def = condition
	return evaluator

static func make_self_condition_evaluator(condition: ConditionDef, body: Node2D) -> SelfConditionEvaluator:
	assert(not condition.abstract)
	var evaluator = lookup(condition.id).condition_script.new() as SelfConditionEvaluator
	evaluator.def = condition
	evaluator.body = body
	return evaluator

static func make_target_node_condition_evaluator(condition: ConditionDef) -> TargetNodeConditionEvaluator:
	assert(not condition.abstract)
	var evaluator = lookup(condition.id).condition_script.new() as TargetNodeConditionEvaluator
	evaluator.def = condition
	return evaluator

static func all_conditions() -> Array[ConditionDef.Id]:
	var all: Array[ConditionDef.Id] = []
	for id in conditions.keys():
		all.append(id as ConditionDef.Id)
	return all
