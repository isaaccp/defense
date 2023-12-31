extends Node

class_name SideComponent

@export_group("Required")
@export var side: Groups.GroupType

@export_group("Debug")
var enemy_groups: Array[String]

func _ready():
	assert(side != Groups.GroupType.UNSPECIFIED)
	if side == Groups.GroupType.CHARACTERS:
		enemy_groups = [Groups.ENEMIES]
	else:
		enemy_groups = [Groups.CHARACTERS, Groups.TOWERS]
		
func is_enemy_node(node: Node2D) -> bool:
	for group in enemy_groups:
		if node.is_in_group(group):
			return true
	return false

func is_enemy(other: SideComponent) -> bool:
	if side == Groups.GroupType.CHARACTERS or side == Groups.GroupType.TOWERS:
		return other.side == Groups.GroupType.ENEMIES
	else:
		return other.side == Groups.GroupType.CHARACTERS or other.side == Groups.GroupType.TOWERS

func enemies() -> Array:
	var nodes = []
	for group in enemy_groups:
		nodes.append_array(get_tree().get_nodes_in_group(group))
	return nodes
