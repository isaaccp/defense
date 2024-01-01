@tool
extends Resource

class_name SkillTreeCollection

@export var skill_trees: Array[SkillTree]

func add(skill_tree: SkillTree):
	skill_trees.append(skill_tree)

func size():
	return skill_trees.size()
