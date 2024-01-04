extends Resource

class_name SkillTypeCollection

# Collection of all skills for a given type (e.g., all actions).
@export var skills: Array[SkillBase]

func add(skill: SkillBase):
	skills.append(skill)

func size():
	return skills.size()
