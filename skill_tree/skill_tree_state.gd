extends Resource

class_name SkillTreeState

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
		
# If set, all actions/targets are available.
@export var full_acquired = false
@export var full_unlocked = false

# TODO: Make dictionaries so it's faster to check unlocked.

func unlocked(skill: Skill) -> bool:
	if full_unlocked:
		return true
	return _skill_in(skill, unlocked_actions, unlocked_target_selections)

func acquired(skill: Skill) -> bool:
	if full_acquired:
		return true
	return _skill_in(skill, acquired_actions, acquired_target_selections)
		
func _skill_in(skill: Skill, actions: Array[ActionDef.Id], target_selections: Array[TargetSelectionDef.Id]):
	assert(skill.skill_type != Skill.SkillType.UNSPECIFIED)
	match skill.skill_type:
		Skill.SkillType.ACTION:
			return skill.action_def.id in actions
		Skill.SkillType.ACTION:
			return skill.target_selection_def.id in target_selections
	return false

static func make_full() -> SkillTreeState:
	var skill_tree_state = SkillTreeState.new()
	skill_tree_state.full = true
	return skill_tree_state
