extends Node

class_name SideComponent

@export_group("Required")
@export var side: Groups.GroupType

@export_group("Debug")
var enemy_group: String

func _ready():
	assert(side != Groups.GroupType.UNSPECIFIED)
	if side == Groups.GroupType.CHARACTERS:
		enemy_group = Groups.ENEMIES
	else:
		enemy_group = Groups.CHARACTERS
		
func is_enemy_node(node: Node2D) -> bool:
	return node.is_in_group(enemy_group)

func is_enemy(side_component: SideComponent) -> bool:
	return side_component.side != side

func enemies() -> Array[Node]:
	return get_tree().get_nodes_in_group(enemy_group)
