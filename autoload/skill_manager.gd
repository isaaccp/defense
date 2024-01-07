@tool
extends Node

var actions = preload("res://skill_tree/skill_type_collections/action_collection.tres")
var conditions = preload("res://skill_tree/skill_type_collections/condition_collection.tres")
var targets = preload("res://skill_tree/skill_type_collections/target_collection.tres")
var target_sorts = preload("res://skill_tree/skill_type_collections/target_sort_collection.tres")

var action_by_id: Dictionary
var condition_by_id: Dictionary
var target_by_id: Dictionary
var target_sort_by_name: Dictionary

func _ready():
	refresh()

func refresh():
	action_by_id.clear()
	condition_by_id.clear()
	target_by_id.clear()
	target_sort_by_name.clear()
	for action in actions.skills:
		action_by_id[action.id] = action
	for condition in conditions.skills:
		condition_by_id[condition.id] = condition
	for target in targets.skills:
		target.validate()
		target_by_id[target.id] = target
	for target_sort in target_sorts.skills:
		target_sort_by_name[target_sort.skill_name] = target_sort

# Action
func lookup_action(id: ActionDef.Id) -> ActionDef:
	return action_by_id[id]

func make_action_instance(id: ActionDef.Id) -> ActionDef:
	var action = lookup_action(id).duplicate(true)
	action.abstract = false
	return action

func restore_rule(saved_rule: RuleDef) -> Rule:
	var rule = Rule.new()
	rule.target_selection = restore_skill(saved_rule.target_selection) as TargetSelectionDef
	rule.condition = restore_skill(saved_rule.condition) as ConditionDef
	rule.action = restore_skill(saved_rule.action) as ActionDef
	return rule

func restore_skill(saved_skill: RuleSkillDef) -> Skill:
	var skill: ParamSkill
	match saved_skill.skill_type:
		Skill.SkillType.ACTION:
			skill = make_action_instance(saved_skill.id)
		Skill.SkillType.TARGET:
			skill = make_target_selection_instance(saved_skill.id)
		Skill.SkillType.CONDITION:
			skill = make_condition_instance(saved_skill.id)
		_:
			assert(false, "Unexpected skill type to restore")
	assert(skill, "Failed to restore new skill instance")
	# This if not needed for real play, but it makes it easier for tests
	# as they can get the default sorter for target selections without
	# setting it.
	# The second part is just for old behaviors that haven't been updated
	# properly and can be eventually removed.
	if saved_skill.params and not saved_skill.params.placeholders.is_empty():
		skill.params = saved_skill.params
	return skill

func make_runnable_action(action_def: ActionDef) -> Action:
	var action = action_def.action_script.new() as Action
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
	var evaluator = condition.evaluator_script.new() as AnyConditionEvaluator
	evaluator.def = condition
	return evaluator

func make_self_condition_evaluator(condition: ConditionDef, actor: Actor) -> SelfConditionEvaluator:
	assert(not condition.abstract)
	var evaluator = condition.evaluator_script.new() as SelfConditionEvaluator
	evaluator.def = condition
	evaluator.actor = actor
	return evaluator

func make_target_actor_condition_evaluator(condition: ConditionDef, actor: Actor) -> TargetActorConditionEvaluator:
	assert(not condition.abstract)
	assert(condition.type in [ConditionDef.Type.TARGET_ACTOR, ConditionDef.Type.TARGET_POSITION])
	var evaluator: TargetActorConditionEvaluator
	if condition.type == ConditionDef.Type.TARGET_ACTOR:
		evaluator = condition.evaluator_script.new() as TargetActorConditionEvaluator
	else:
		var position_evaluator = make_position_condition_evaluator(condition, actor)
		evaluator = PositionToActorConditionEvaluatorAdapter.new(position_evaluator)
	evaluator.def = condition
	evaluator.actor = actor
	return evaluator

func make_position_condition_evaluator(condition: ConditionDef, actor: Actor) -> PositionConditionEvaluator:
	assert(not condition.abstract)
	assert(condition.type in [ConditionDef.Type.TARGET_POSITION])
	var evaluator = condition.evaluator_script.new() as PositionConditionEvaluator
	evaluator.def = condition
	evaluator.actor = actor
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
	if target.sortable:
		target.params.set_placeholder_value(SkillParams.PlaceholderId.SORT, target.default_sort)
	return target

func make_actor_target_selector(target: TargetSelectionDef, target_actor_evaluator: TargetActorConditionEvaluator) -> NodeTargetSelector:
	assert(not target.abstract)
	assert(target.type == Target.Type.ACTOR)
	var selector = target.selector_script.new() as NodeTargetSelector
	selector.def = target
	selector.condition_evaluator = target_actor_evaluator
	return selector

func make_position_target_selector(target: TargetSelectionDef, target_position_evaluator: PositionConditionEvaluator) -> PositionTargetSelector:
	assert(not target.abstract)
	assert(target.type == Target.Type.POSITION)
	var selector = target.selector_script.new() as PositionTargetSelector
	selector.def = target
	selector.condition_evaluator = target_position_evaluator
	return selector

func all_target_selections() -> Array[TargetSelectionDef.Id]:
	var all: Array[TargetSelectionDef.Id] = []
	for id in target_by_id.keys():
		all.append(id as TargetSelectionDef.Id)
	return all

# TargetSort.
# Stateless and not parameterizable, so no need to make instances.
func lookup_target_sort(name: StringName) -> TargetSort:
	return target_sort_by_name[name]

func make_actor_target_sorter(target_sort: TargetSort) -> ActorTargetSorter:
	assert(target_sort.type in [TargetSort.Type.ACTOR, TargetSort.Type.POSITION])
	var sorter: ActorTargetSorter
	if target_sort.type == TargetSort.Type.ACTOR:
		sorter = target_sort.sorter_script.new() as ActorTargetSorter
	else:
		var position_sorter = make_position_target_sorter(target_sort)
		sorter = PositionToActorTargetSorterAdapter.new(position_sorter)
	sorter.def = target_sort
	return sorter

func make_position_target_sorter(target_sort: TargetSort) -> PositionTargetSorter:
	assert(target_sort.type in [TargetSort.Type.POSITION])
	var sorter = target_sort.sorter_script.new() as PositionTargetSorter
	sorter.def = target_sort
	return sorter

func all_target_sorts() -> Array[StringName]:
	var all: Array[StringName] = []
	for skill_name in target_sort_by_name.keys():
		all.append(skill_name)
	return all
