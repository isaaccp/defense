extends Resource

class_name Target

enum Type {
	UNSPECIFIED,
	NODE,
}

var type: Type
var node: Node2D:
	get:
		assert(type == Type.NODE)
		if not is_instance_valid(node):
			node = null
		return node

func valid() -> bool:
	if type == Type.UNSPECIFIED:
		return false
	if type == Type.NODE:
		return node != null and is_instance_valid(node)
	return false

func equals(other: Target) -> bool:
	if type == other.type:
		if type == Type.NODE:
			return node == other.node
	return false

func _to_string():
	match type:
		Type.NODE:
			return node.actor_name

static func make_invalid() -> Target:
	return Target.new()

static func make_node_target(node_: Node2D) -> Target:
	var target = Target.new()
	target.type = Type.NODE
	target.node = node_
	return target
