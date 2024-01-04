extends Resource

class_name SkillTreeState

# TODO: Replace back all instances of "Resource" with "Skill".

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
func unlocked(skill: Resource) -> bool:
	return _skill_in(skill, StateType.UNLOCKED)

func acquired(skill: Resource) -> bool:
	return _skill_in(skill, StateType.ACQUIRED)

func can_acquire(skill: Resource) -> bool:
	if acquired(skill):
		return false
	if not unlocked(skill):
		return false
	if skill.parent and not acquired(skill.parent):
		return false
	return true

func can_unlock(skill: Resource) -> bool:
	if unlocked(skill):
		return false
	if skill.parent and not unlocked(skill.parent):
		return false
	return true

func acquire(skill: Resource):
	assert(not acquired(skill), "Skill already acquired!")
	assert(unlocked(skill), "Skill not unlocked yet!")
	_add_skill_to(skill, StateType.ACQUIRED)

func unlock(skill: Resource):
	# TODO: Add prerequisites for unlocking.
	assert(not unlocked(skill), "Skill already unlocked!")
	_add_skill_to(skill, StateType.UNLOCKED)

func _skill_in(skill: Resource, state_type: StateType):
	assert(skill.skill_type != Skill.SkillType.UNSPECIFIED)
	if _full(state_type):
		return true
	match skill.skill_type:
		Skill.SkillType.ACTION:
			return skill.get_id() in _actions(state_type)
		Skill.SkillType.TARGET:
			return skill.get_id() in _target_selections(state_type)
		Skill.SkillType.CONDITION:
			return skill.get_id() in _conditions(state_type)
	return false

func _add_skill_to(skill: Resource, state_type: StateType):
	assert(skill.skill_type != Skill.SkillType.UNSPECIFIED)
	match skill.skill_type:
		Skill.SkillType.ACTION:
			_actions(state_type).append(skill.get_id())
		Skill.SkillType.TARGET:
			_target_selections(state_type).append(skill.get_id())
		Skill.SkillType.CONDITION:
			_conditions(state_type).append(skill.get_id())

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

func _conditions(state_type: StateType) -> Array[ConditionDef.Id]:
	if state_type == StateType.ACQUIRED:
		return acquired_conditions
	else:
		return unlocked_conditions

func _full(state_type: StateType) -> bool:
	if state_type == StateType.ACQUIRED:
		return full_acquired
	else:
		return full_unlocked

# Used for tutorial levels, etc that need to add to a tree.
# TODO: Don't add duplicates.
func add(other: SkillTreeState):
	unlocked_actions += other.unlocked_actions
	unlocked_target_selections += other.unlocked_target_selections
	unlocked_conditions += other.unlocked_target_selections
	acquired_actions += other.acquired_actions
	acquired_target_selections += other.acquired_target_selections
	acquired_conditions += other.acquired_target_selections
