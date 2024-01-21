@tool
extends Node

const actions = preload("res://skill_tree/skill_type_collections/action_collection.tres")
const conditions = preload("res://skill_tree/skill_type_collections/condition_collection.tres")
const targets = preload("res://skill_tree/skill_type_collections/target_collection.tres")
const target_sorts = preload("res://skill_tree/skill_type_collections/target_sort_collection.tres")
const meta_skills = preload("res://skill_tree/skill_type_collections/meta_skill_collection.tres")

var action_by_name: Dictionary
var condition_by_name: Dictionary
var target_by_name: Dictionary
var target_sort_by_name: Dictionary
var meta_skill_by_name: Dictionary

var skill_by_name: Dictionary
var all_skills: Array[StringName]

func _init():
	# TODO: Simplify this repetitive code.
	all_skills.clear()
	action_by_name.clear()
	condition_by_name.clear()
	target_by_name.clear()
	target_sort_by_name.clear()
	meta_skill_by_name.clear()
	for action in actions.skills:
		action_by_name[action.skill_name] = action
		all_skills.append(action.skill_name)
		skill_by_name[action.skill_name] = action
	for condition in conditions.skills:
		condition_by_name[condition.skill_name] = condition
		all_skills.append(condition.skill_name)
		skill_by_name[condition.skill_name] = condition
	for target in targets.skills:
		target.validate()
		target_by_name[target.skill_name] = target
		all_skills.append(target.skill_name)
		skill_by_name[target.skill_name] = target
	for target_sort in target_sorts.skills:
		target_sort_by_name[target_sort.skill_name] = target_sort
		all_skills.append(target_sort.skill_name)
		skill_by_name[target_sort.skill_name] = target_sort
	for meta_skill in meta_skills.skills:
		meta_skill_by_name[meta_skill.skill_name] = meta_skill
		all_skills.append(meta_skill.skill_name)
		skill_by_name[meta_skill.skill_name] = meta_skill

func lookup_skill(name: StringName) -> Skill:
	return skill_by_name[name]

# Action
func lookup_action(name: StringName) -> ActionDef:
	return action_by_name[name]

func make_action_instance(name: StringName) -> ActionDef:
	var action = lookup_action(name).duplicate(true)
	action.abstract = false
	return action

func restore_rule(saved_rule: RuleDef) -> Rule:
	var rule = Rule.new()
	rule.target_selection = restore_skill(saved_rule.target_selection) as TargetSelectionDef
	rule.condition = restore_skill(saved_rule.condition) as ConditionDef
	rule.action = restore_skill(saved_rule.action) as ActionDef
	return rule

func restore_skill(saved_skill: RuleSkillDef) -> Skill:
	# As of now all skills are ParamSkill subclasses.
	var skill: ParamSkill
	match saved_skill.skill_type:
		Skill.SkillType.ACTION:
			skill = make_action_instance(saved_skill.name)
		Skill.SkillType.TARGET:
			skill = make_target_selection_instance(saved_skill.name)
		Skill.SkillType.CONDITION:
			skill = make_condition_instance(saved_skill.name)
		_:
			assert(false, "Unexpected skill type to restore")
	assert(skill, "Failed to restore new skill instance")
	skill.params = saved_skill.params
	return skill

func all_actions() -> Array[StringName]:
	var all: Array[StringName] = []
	for name in action_by_name.keys():
		all.append(name)
	return all

# Condition
func lookup_condition(name: StringName) -> ConditionDef:
	return condition_by_name[name]

func make_condition_instance(name: StringName) -> ConditionDef:
	var condition = lookup_condition(name).duplicate(true)
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
	if not condition.type in [ConditionDef.Type.TARGET_ACTOR, ConditionDef.Type.TARGET_POSITION]:
		return null
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
	if not condition.type in [ConditionDef.Type.TARGET_POSITION]:
		return null
	var evaluator = condition.evaluator_script.new() as PositionConditionEvaluator
	evaluator.def = condition
	evaluator.actor = actor
	return evaluator

func all_conditions() -> Array[StringName]:
	var all: Array[StringName] = []
	for name in condition_by_name.keys():
		all.append(name)
	return all

# Target

func lookup_target(name: StringName) -> TargetSelectionDef:
	return target_by_name[name]

func make_target_selection_instance(name: StringName) -> TargetSelectionDef:
	var target = lookup_target(name).duplicate(true)
	target.abstract = false
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

func all_target_selections() -> Array[StringName]:
	var all: Array[StringName] = []
	for name in target_by_name.keys():
		all.append(name)
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

# Meta skills.
func all_meta_skills() -> Array[StringName]:
	var all: Array[StringName] = []
	for skill_name in meta_skill_by_name.keys():
		all.append(skill_name)
	return all

# Behavior.
func restore_behavior(stored_behavior: StoredBehavior) -> Behavior:
	var behavior = Behavior.new()
	for stored_rule in stored_behavior.stored_rules:
		var rule = SkillManager.restore_rule(stored_rule)
		behavior.rules.append(rule)
	return behavior
