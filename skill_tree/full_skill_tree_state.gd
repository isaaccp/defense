extends SkillTreeState

class_name FullSkillTreeState

func _init():
	super()
	var all_skills: Array[StringName] = []
	all_skills.append_array(SkillManager.all_actions())
	all_skills.append_array(SkillManager.all_target_selections())
	all_skills.append_array(SkillManager.all_target_sorts())
	all_skills.append_array(SkillManager.all_conditions())
	all_skills.append_array(SkillManager.all_meta_skills())
	skills = all_skills
