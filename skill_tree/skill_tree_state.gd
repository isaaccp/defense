extends Resource

class_name SkillTreeState

@export var actions: Array[ActionDef.Id]:
	get:
		if full:
			return ActionManager.all_actions()
		return actions
		
@export var target_selections: Array[TargetSelectionDef.Id]:
	get:
		if full:
			return TargetSelectionManager.all_target_selections()
		return target_selections
		
# If set, all actions/targets are available.
@export var full = false

# TODO: Make dictionaries so it's faster to check unlocked.

func unlocked(skill: Skill) -> bool:
	if full:
		return true
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
