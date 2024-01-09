extends Resource

class_name SkillTreeState

const always = preload("res://skill_tree/conditions/always.tres")

@export var acquired_skills: Array[StringName] = [always.skill_name]
@export var unlocked_skills: Array[StringName] = [always.skill_name]

# If set, all skills are acquired/unlocked..
@export var full_acquired = false
@export var full_unlocked = false

var acquired_by_name: Dictionary
var unlocked_by_name: Dictionary

var acquired_actions: Array[StringName]:
	get:
		if full_acquired:
			return SkillManager.all_actions()
		return _cast(acquired_by_name[Skill.SkillType.ACTION].keys())

var acquired_target_selections: Array[StringName]:
	get:
		if full_acquired:
			return SkillManager.all_target_selections()
		return _cast(acquired_by_name[Skill.SkillType.TARGET].keys())

var acquired_target_sorts: Array[StringName]:
	get:
		if full_acquired:
			return SkillManager.all_target_sorts()
		return _cast(acquired_by_name[Skill.SkillType.TARGET_SORT].keys())

var acquired_conditions: Array[StringName]:
	get:
		if full_acquired:
			return SkillManager.all_conditions()
		return _cast(acquired_by_name[Skill.SkillType.CONDITION].keys())

var unlocked_actions: Array[StringName]:
	get:
		if full_unlocked:
			return SkillManager.all_actions()
		return _cast(unlocked_by_name[Skill.SkillType.ACTION].keys())

var unlocked_target_selections: Array[StringName]:
	get:
		if full_unlocked:
			return SkillManager.all_target_selections()
		return _cast(unlocked_by_name[Skill.SkillType.TARGET].keys())

var unlocked_target_sorts: Array[StringName]:
	get:
		if full_unlocked:
			return SkillManager.all_target_sorts()
		return _cast(unlocked_by_name[Skill.SkillType.TARGET_SORT].keys())

var unlocked_conditions: Array[StringName]:
	get:
		if full_unlocked:
			return SkillManager.all_conditions()
		return _cast(unlocked_by_name[Skill.SkillType.CONDITION].keys())

func _init():
	for skill_type in Skill.SkillType.values():
		if skill_type == Skill.SkillType.UNSPECIFIED:
			continue
		acquired_by_name[skill_type] = {}
		unlocked_by_name[skill_type] = {}
	_process.call_deferred()

func _process():
	_process_skills(acquired_skills, acquired_by_name)
	_process_skills(unlocked_skills, unlocked_by_name)

func _process_skills(skills: Array[StringName], by_name: Dictionary):
	for skill in skills:
		by_name[skill] = true

func unlocked(skill: Skill) -> bool:
	return _skill_in(skill, StateType.UNLOCKED)

func acquired(skill: Skill) -> bool:
	return _skill_in(skill, StateType.ACQUIRED)

func can_acquire(skill: Skill) -> bool:
	if acquired(skill):
		return false
	if not unlocked(skill):
		return false
	if skill.parent and not acquired(skill.parent):
		return false
	return true

func can_unlock(skill: Skill) -> bool:
	if unlocked(skill):
		return false
	if skill.parent and not unlocked(skill.parent):
		return false
	return true

func acquire(skill: Skill):
	assert(not acquired(skill), "Skill already acquired!")
	assert(unlocked(skill), "Skill not unlocked yet!")
	_add_skill_to(skill, StateType.ACQUIRED)

func unlock(skill: Skill):
	# TODO: Add prerequisites for unlocking.
	assert(not unlocked(skill), "Skill already unlocked!")
	_add_skill_to(skill, StateType.UNLOCKED)

func _skill_in(skill: Skill, state_type: StateType):
	assert(skill.skill_type != Skill.SkillType.UNSPECIFIED)
	if _full(state_type):
		return true
	var state_skills = _skills_dict_by_state_type(state_type)
	return skill.skill_name in state_skills[skill.skill_type]

func _add_skill_to(skill: Skill, state_type: StateType):
	assert(skill.skill_type != Skill.SkillType.UNSPECIFIED)
	var skills = _skills_by_state_type(state_type)
	var state_skills = _skills_dict_by_state_type(state_type)
	skills.append(skill.skill_name)
	state_skills[skill.skill_type][skill.skill_name] = true

# For handling unlocked/acquired more easily.
enum StateType {
	UNLOCKED,
	ACQUIRED,
}

func _skills_by_state_type(state_type: StateType) -> Array[StringName]:
	if state_type == StateType.ACQUIRED:
		return acquired_skills
	else:
		return unlocked_skills

func _skills_dict_by_state_type(state_type: StateType) -> Dictionary:
	if state_type == StateType.ACQUIRED:
		return acquired_by_name
	else:
		return unlocked_by_name

func _full(state_type: StateType) -> bool:
	if state_type == StateType.ACQUIRED:
		return full_acquired
	else:
		return full_unlocked

# Used for tutorial levels, etc that need to add to a tree.
# TODO: Don't add duplicates.
func add(other: SkillTreeState):
	unlocked_skills += other.unlocked_skills
	acquired_skills += other.acquired_skills

# TODO: Remove if we ever have typed dictionaries.
func _cast(skill_names: Array) -> Array[StringName]:
	var names: Array[StringName] = []
	names.assign(skill_names)
	return names
