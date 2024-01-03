extends Resource

class_name SkillTreeState

# Unclear if we actually need this here yet.
@export var skill_tree_collection = preload("res://skill_tree/trees/skill_tree_collection.tres")

@export var acquired_actions: Array[ActionDef.Id]:
	get:
		if full_acquired:
			return ActionManager.all_actions()
		return acquired_actions

@export var acquired_target_selections: Array[TargetSelectionDef.Id]:
	get:
		if full_acquired:
			return TargetSelectionManager.all_target_selections()
		return acquired_target_selections

@export var acquired_conditions: Array[ConditionDef.Id] = [ConditionDef.Id.ALWAYS]:
	get:
		if full_acquired:
			return ConditionManager.all_conditions()
		return acquired_conditions

@export var unlocked_actions: Array[ActionDef.Id]:
	get:
		if full_unlocked:
			return ActionManager.all_actions()
		return unlocked_actions

@export var unlocked_target_selections: Array[TargetSelectionDef.Id]:
	get:
		if full_unlocked:
			return TargetSelectionManager.all_target_selections()
		return unlocked_target_selections

@export var unlocked_conditions: Array[ConditionDef.Id] = [ConditionDef.Id.ALWAYS]:
	get:
		if full_unlocked:
			return ConditionManager.all_conditions()
		return unlocked_conditions

# If set, all actions/targets are available.
@export var full_acquired = false
@export var full_unlocked = false

# TODO: Make dictionaries so it's faster to check unlocked, etc.
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
	match skill.skill_type:
		Skill.SkillType.ACTION:
			return skill.action_def.id in _actions(state_type)
		Skill.SkillType.ACTION:
			return skill.target_selection_def.id in _target_selections(state_type)
	return false

func _add_skill_to(skill: Skill, state_type: StateType):
	assert(skill.skill_type != Skill.SkillType.UNSPECIFIED)
	match skill.skill_type:
		Skill.SkillType.ACTION:
			_actions(state_type).append(skill.action_def.id)
		Skill.SkillType.ACTION:
			_target_selections(state_type).append(skill.target_selection_def.id)

static func make_full() -> SkillTreeState:
	var skill_tree_state = SkillTreeState.new()
	skill_tree_state.full = true
	return skill_tree_state

# For handling unlocked/acquired more easily.
enum StateType {
	UNLOCKED,
	ACQUIRED,
}

func _actions(state_type: StateType) -> Array[ActionDef.Id]:
	if state_type == StateType.ACQUIRED:
		return acquired_actions
	else:
		return unlocked_actions

func _target_selections(state_type: StateType) -> Array[TargetSelectionDef.Id]:
	if state_type == StateType.ACQUIRED:
		return acquired_target_selections
	else:
		return unlocked_target_selections

func _full(state_type: StateType) -> bool:
	if state_type == StateType.ACQUIRED:
		return full_acquired
	else:
		return full_unlocked
