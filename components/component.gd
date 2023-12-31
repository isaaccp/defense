extends RefCounted

class_name Component

static func get_or_die(node: Node, component_name: String) -> Node:
	var component = get_or_null(node, component_name)
	assert(component, "Couldn't find wanted component")
	return component

static func get_or_null(node: Node, component_name: String) -> Node:
	return node.get_node_or_null(component_name)
