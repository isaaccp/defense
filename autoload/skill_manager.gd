@tool
extends Node

const actions = preload("res://skill_tree/skill_type_collections/action_collection.tres")
const conditions = preload("res://skill_tree/skill_type_collections/condition_collection.tres")

# TODO: Try moving this to the Resource at some point again.
const action_scripts = {
	ActionDef.Id.MOVE_TO: preload("res://behavior/actions/move_to_action.gd"),
	ActionDef.Id.SWORD_ATTACK: preload("res://behavior/actions/sword_attack_action.gd"),
	ActionDef.Id.BOW_ATTACK: preload("res://behavior/actions/bow_attack_action.gd"),
	ActionDef.Id.CHARGE: preload("res://behavior/actions/charge_action.gd"),
	ActionDef.Id.MULTI_SHOT: preload("res://behavior/actions/multi_shot_action.gd"),
	ActionDef.Id.HEAL: preload("res://behavior/actions/heal_action.gd"),
}

const condition_scripts = {
	ConditionDef.Id.ALWAYS: preload("res://behavior/conditions/condition_always.gd"),
	ConditionDef.Id.TARGET_HEALTH: preload("res://behavior/conditions/health_target_node_condition_evaluator.gd"),
}

var action_by_id: Dictionary
var condition_by_id: Dictionary
var target_selection_by_id: Dictionary

func _ready():
	for action in actions.skills:
		action_by_id[action.id] = action
	for condition in conditions.skills:
		condition_by_id[condition.id] = condition

# Action
# TODO: Update to the same way as condition.
func make_action(action_def: ActionDef) -> Action:
	var action = action_scripts[action_def.id].new() as Action
	action.def = action_def
	return action

func all_actions() -> Array[ActionDef.Id]:
	var all: Array[ActionDef.Id] = []
	for id in action_by_id.keys():
		all.append(id as ActionDef.Id)
	return all

# Condition
func lookup_condition(id: ConditionDef.Id) -> ConditionDef:
	return condition_by_id[id]

func make_condition_instance(id: ConditionDef.Id) -> ConditionDef:
	var condition = lookup_condition(id).duplicate(true)
	condition.abstract = false
	return condition

func make_any_condition_evaluator(condition: ConditionDef) -> AnyConditionEvaluator:
	assert(not condition.abstract)
	var evaluator = condition_scripts[condition.id].new() as AnyConditionEvaluator
	evaluator.def = condition
	return evaluator

func make_self_condition_evaluator(condition: ConditionDef, body: Node2D) -> SelfConditionEvaluator:
	assert(not condition.abstract)
	var evaluator = condition_scripts[condition.id].new() as SelfConditionEvaluator
	evaluator.def = condition
	evaluator.body = body
	return evaluator

func make_target_node_condition_evaluator(condition: ConditionDef) -> TargetNodeConditionEvaluator:
	assert(not condition.abstract)
	var evaluator = condition_scripts[condition.id].new() as TargetNodeConditionEvaluator
	evaluator.def = condition
	return evaluator

func all_conditions() -> Array[ConditionDef.Id]:
	var all: Array[ConditionDef.Id] = []
	for id in condition_by_id.keys():
		all.append(id as ConditionDef.Id)
	return all
