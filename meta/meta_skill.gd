@tool
extends Skill

class_name MetaSkill

@export_multiline var description: String

func _init():
	skill_type = SkillType.META_SKILL

func name() -> String:
	return skill_name

func full_description() -> String:
	return "%s\n%s" % [name(), description]
