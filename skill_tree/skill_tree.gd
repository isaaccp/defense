@tool
extends Resource

class_name SkillTree

enum TreeType {
	UNSPECIFIED,
	GENERAL,
	WARRIOR,
	ROGUE,
	CLERIC,
	WIZARD,
	META,
}

@export var tree_type: TreeType
@export var skills: Array[Skill]

func add(skill: Skill):
	skills.append(skill)

func size():
	return skills.size()

func validate():
	pass

static func tree_type_filesystem_string(tree_type: TreeType) -> String:
	assert(tree_type != TreeType.UNSPECIFIED)
	return TreeType.keys()[tree_type].to_lower()
