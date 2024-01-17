@tool
extends Skill

class_name MetaSkill

@export var description: String

func _init():
	skill_type = SkillType.META

func name() -> String:
	return skill_name

func full_description() -> String:
	return "%s\n%s" % [name(), description]
