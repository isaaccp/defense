@tool
extends Node

const actions = preload("res://skill_tree/skill_type_collections/action_collection.tres")
const conditions = preload("res://skill_tree/skill_type_collections/condition_collection.tres")
const targets = preload("res://skill_tree/skill_type_collections/target_collection.tres")

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

const target_scripts = {
	# TODO: Refactor all those so they return a list of nodes to
	# filter through condition instead of having to do it in each.
	TargetSelectionDef.Id.CLOSEST_ENEMY: preload("res://behavior/target_selection/target_selection_closest_enemy.gd"),
	TargetSelectionDef.Id.TOWER: preload("res://behavior/target_selection/target_selection_tower.gd"),
	TargetSelectionDef.Id.SELF: preload("res://behavior/target_selection/target_selection_self.gd"),
}

var action_by_id: Dictionary
var condition_by_id: Dictionary
var target_by_id: Dictionary

func _ready():
	for action in actions.skills:
		action_by_id[action.id] = action
	for condition in conditions.skills:
		condition_by_id[condition.id] = condition
	for target in targets.skills:
		target_by_id[target.id] = target

# Action
func lookup_action(id: ActionDef.Id) -> ActionDef:
	return action_by_id[id]

func make_action_instance(id: ActionDef.Id) -> ActionDef:
	var action = lookup_action(id).duplicate(true)
	# action.abstract = false
	return action

func make_runnable_action(action_def: ActionDef) -> Action:
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

# Target
func select_target(target_selection_def: TargetSelectionDef, evaluator: TargetNodeConditionEvaluator, action: Action, body: CharacterBody2D, side_component: SideComponent) -> Target:
	var target_selection = target_scripts[target_selection_def.id]
	return target_selection.select_target(target_selection_def, evaluator, action, body, side_component)

func all_target_selections() -> Array[TargetSelectionDef.Id]:
	var all: Array[TargetSelectionDef.Id] = []
	for id in target_by_id.keys():
		all.append(id as TargetSelectionDef.Id)
	return all
