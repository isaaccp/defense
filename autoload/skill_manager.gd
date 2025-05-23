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

# Skill.
func lookup_skill(name: StringName) -> Skill:
	return skill_by_name[name]

func restore_rule(stored_rule: RuleDef) -> Rule:
	var rule = Rule.new()
	rule.target_selection = restore_skill(stored_rule.target_selection) as TargetSelectionDef
	rule.condition = restore_skill(stored_rule.condition) as ConditionDef
	rule.action = restore_skill(stored_rule.action) as ActionDef
	return rule

func restore_skill(stored_skill: StoredSkill) -> Skill:
	# Do not do a deep duplicate. clone() will duplicate the properties that
	# strictly needed. In particular, we must not duplicate the GDscripts in
	# actions, etc as it'd trigger reparsing any time we do a restore.
	var skill = lookup_skill(stored_skill.name).clone()
	if stored_skill is StoredParamSkill:
		assert(skill is ParamSkill)
		skill.params = stored_skill.params
		if skill.params.placeholder_set(SkillParams.PlaceholderId.SORT):
			var stored_sort = skill.params.get_placeholder_value(SkillParams.PlaceholderId.SORT)
			skill.restored_skill_params.sort = restore_skill(stored_sort)
	return skill

# Action
func lookup_action(name: StringName) -> ActionDef:
	return action_by_name[name]

func make_action_instance(name: StringName) -> ActionDef:
	var action = lookup_action(name).duplicate(true)
	return action

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
	return condition

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
	return target

func all_target_selections() -> Array[StringName]:
	var all: Array[StringName] = []
	for name in target_by_name.keys():
		all.append(name)
	return all

# TargetSort.
# Stateless and not parameterizable, so no need to make instances.
func lookup_target_sort(name: StringName) -> TargetSort:
	return target_sort_by_name[name]

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
