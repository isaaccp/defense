extends Resource

class_name SkillTypeCollection

# Collection of all skills for a given type (e.g., all actions).
@export var skills: Array[Skill]

func add(skill: Skill):
	skills.append(skill)

func size():
	return skills.size()
