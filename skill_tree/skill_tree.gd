@tool
extends Resource

class_name SkillTree

enum TreeType {
	UNSPECIFIED,
	GENERAL,
	WARRIOR,
	ROGUE,
	CLERIC,
}

@export var tree_type: TreeType
# Set back to Skill.
@export var skills: Array[Resource]

# TODO: Switch back to Skill once we no longer have Skill vs Skill.
func add(skill: Resource):
	skills.append(skill)

func size():
	return skills.size()

func validate():
	assert(true)

static func tree_type_filesystem_string(tree_type: TreeType) -> String:
	assert(tree_type != TreeType.UNSPECIFIED)
	return TreeType.keys()[tree_type].to_lower()
