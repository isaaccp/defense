extends RefCounted
class_name SkillStyles

# Static preloaded profiles for global access
const TARGET: SkillStyleProfile = preload("res://ui/resources/target_skill_style_profile.tres")
const ACTION: SkillStyleProfile = preload("res://ui/resources/action_skill_style_profile.tres")
const CONDITION: SkillStyleProfile = preload("res://ui/resources/condition_skill_style_profile.tres")

static var profiles: Dictionary[String, SkillStyleProfile] = {
	"target": TARGET,
	"action": ACTION,
	"condition": CONDITION,
}

static func profile_for_slot(slot_type: BehaviorEditorTypes.SlotType) -> SkillStyleProfile:
	match slot_type:
		BehaviorEditorTypes.SlotType.TARGET: return TARGET
		BehaviorEditorTypes.SlotType.CONDITION: return CONDITION
		BehaviorEditorTypes.SlotType.ACTION: return ACTION
	return ACTION

static func profile_for_skill_type(skill_type: Skill.SkillType) -> SkillStyleProfile:
	# Skill.SkillType enum values:
	# 1: ACTION, 2: TARGET, 3: CONDITION, 4: TARGET_SORT, 5: META_SKILL
	match skill_type:
		Skill.SkillType.ACTION: return ACTION      # ACTION
		Skill.SkillType.TARGET: return TARGET      # TARGET
		Skill.SkillType.CONDITION: return CONDITION   # CONDITION
		Skill.SkillType.TARGET_SORT: return TARGET      # TARGET_SORT
		Skill.SkillType.META_SKILL: return TARGET      # META_SKILL
	return ACTION
