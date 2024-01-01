@tool
extends Resource

class_name SkillCollection

@export var skills: Array[Skill]

func add(skill: Skill):
	skills.append(skill)

func size():
	return skills.size()

func validate():
	assert(true)
