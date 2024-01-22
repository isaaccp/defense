@tool
extends Resource

class_name SkillTree

@export var tree_type: Skill.TreeType
@export var skills: Array[Skill]

func add(skill: Skill):
	skills.append(skill)

func size():
	return skills.size()

func validate():
	pass

static func tree_type_filesystem_string(tree_type: Skill.TreeType) -> String:
	assert(tree_type != Skill.TreeType.UNSPECIFIED)
	return Skill.TreeType.keys()[tree_type].to_lower()
