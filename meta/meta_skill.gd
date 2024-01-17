@tool
extends Skill

class_name MetaSkill

@export_multiline var description_text: String = "<missing description>"

func _init():
	skill_type = SkillType.META_SKILL

func name() -> String:
	return skill_name

func description() -> String:
	return description_text
