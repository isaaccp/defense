@tool
extends Node

class_name NewComponent

const component = &"NewComponent"

@export_group("Required")
# Required fields.

@export_group("Optional")
# Optional fields.


func run():
	pass

static func get_or_null(node: Node) -> NewComponent:
	return Component.get_or_null(node, component) as NewComponent

static func get_or_die(node: Node) -> NewComponent:
	var component = get_or_null(node)
	assert(component)
	return component

