@tool
extends Node

var actions = preload("res://skill_tree/skill_type_collections/action_collection.tres")
var conditions = preload("res://skill_tree/skill_type_collections/condition_collection.tres")
var targets = preload("res://skill_tree/skill_type_collections/target_collection.tres")
var target_sorts = preload("res://skill_tree/skill_type_collections/target_sort_collection.tres")

# TODO: Try moving this to the Resource at some point again.
var action_scripts = {
	ActionDef.Id.MOVE_TO: preload("res://behavior/actions/move_to_action.gd"),
	ActionDef.Id.SWORD_ATTACK: preload("res://behavior/actions/sword_attack_action.gd"),
	ActionDef.Id.BOW_ATTACK: preload("res://behavior/actions/bow_attack_action.gd"),
	ActionDef.Id.CHARGE: preload("res://behavior/actions/charge_action.gd"),
	ActionDef.Id.MULTI_SHOT: preload("res://behavior/actions/multi_shot_action.gd"),
	ActionDef.Id.HEAL: preload("res://behavior/actions/heal_action.gd"),
	ActionDef.Id.HOLD_PERSON: preload("res://behavior/actions/hold_person_action.gd"),
	ActionDef.Id.BLINK_AWAY: preload("res://behavior/actions/blink_away_action.gd"),
	ActionDef.Id.BLINK_TO: preload("res://behavior/actions/blink_to_action.gd"),
	ActionDef.Id.TELEPORT_AWAY: preload("res://behavior/actions/teleport_away_action.gd"),
	ActionDef.Id.TELEPORT_TO: preload("res://behavior/actions/teleport_to_action.gd"),
}

var condition_scripts = {
	ConditionDef.Id.ALWAYS: preload("res://behavior/conditions/condition_always.gd"),
	ConditionDef.Id.TARGET_HEALTH: preload("res://behavior/conditions/health_target_node_condition_evaluator.gd"),
	ConditionDef.Id.ONCE: preload("res://behavior/conditions/condition_once.gd"),
	ConditionDef.Id.TARGET_DISTANCE: preload("res://behavior/conditions/distance_target_node_condition_evaluator.gd"),
	ConditionDef.Id.TIMES: preload("res://behavior/conditions/condition_times.gd"),
}

var target_scripts = {
	TargetSelectionDef.Id.CLOSEST_ENEMY: preload("res://behavior/target_selection/closest_enemy_target_selector.gd"),
	TargetSelectionDef.Id.TOWER: preload("res://behavior/target_selection/tower_target_selector.gd"),
	TargetSelectionDef.Id.SELF: preload("res://behavior/target_selection/self_target_selector.gd"),
	TargetSelectionDef.Id.SELF_OR_ALLY: preload("res://behavior/target_selection/self_or_ally_target_selector.gd"),
	TargetSelectionDef.Id.ALLY: preload("res://behavior/target_selection/ally_target_selector.gd"),
	TargetSelectionDef.Id.FARTHEST_ENEMY: preload("res://behavior/target_selection/farthest_enemy_target_selector.gd"),
}

var target_sort_scripts = {
	TargetSort.Id.CLOSEST_FIRST: null,
}

var action_by_id: Dictionary
var condition_by_id: Dictionary
var target_by_id: Dictionary
var target_sort_by_id: Dictionary

func _ready():
	refresh()

func refresh():
	action_by_id.clear()
	condition_by_id.clear()
	target_by_id.clear()
	target_sort_by_id.clear()
	for action in actions.skills:
		action_by_id[action.id] = action
	for condition in conditions.skills:
		condition_by_id[condition.id] = condition
	for target in targets.skills:
		target.validate()
		target_by_id[target.id] = target
	for target_sort in target_sorts.skills:
		target_sort_by_id[target_sort.id] = target_sort

# Action
func lookup_action(id: ActionDef.Id) -> ActionDef:
	return action_by_id[id]

func make_action_instance(id: ActionDef.Id) -> ActionDef:
	var action = lookup_action(id).duplicate(true)
	action.abstract = false
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

func make_target_node_condition_evaluator(condition: ConditionDef, body: Node2D) -> TargetNodeConditionEvaluator:
	assert(not condition.abstract)
	var evaluator = condition_scripts[condition.id].new() as TargetNodeConditionEvaluator
	evaluator.def = condition
	evaluator.body = body
	return evaluator

func all_conditions() -> Array[ConditionDef.Id]:
	var all: Array[ConditionDef.Id] = []
	for id in condition_by_id.keys():
		all.append(id as ConditionDef.Id)
	return all

# Target

func lookup_target(id: TargetSelectionDef.Id) -> TargetSelectionDef:
	return target_by_id[id]

func make_target_selection_instance(id: TargetSelectionDef.Id) -> TargetSelectionDef:
	var target = lookup_target(id).duplicate(true)
	target.abstract = false
	return target

func make_actor_target_selector(target: TargetSelectionDef, target_node_evaluator: TargetNodeConditionEvaluator) -> NodeTargetSelector:
	assert(not target.abstract)
	var selector = target_scripts[target.id].new() as NodeTargetSelector
	selector.def = target
	selector.condition_evaluator = target_node_evaluator
	return selector

func all_target_selections() -> Array[TargetSelectionDef.Id]:
	var all: Array[TargetSelectionDef.Id] = []
	for id in target_by_id.keys():
		all.append(id as TargetSelectionDef.Id)
	return all

# TargetSort.
# Stateless and not parameterizable, so no need to make instances.
func lookup_target_sort(id: TargetSort.Id) -> TargetSort:
	return target_sort_by_id[id]

func all_target_sorts() -> Array[TargetSort.Id]:
	var all: Array[TargetSort.Id] = []
	for id in target_sort_by_id.keys():
		all.append(id as TargetSort.Id)
	return all
