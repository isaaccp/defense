@tool
extends RefCounted

class_name Component

static func get_or_die(node: Node, component_name: String) -> Node:
	var component = get_or_null(node, component_name)
	if not component:
		push_error("Couldn't find component '%s' on '%s'" % [component_name, node.name if node else "<null>"])
	return component

static func get_or_null(node: Node, component_name: String) -> Node:
	return node.get_node_or_null(component_name)

static func get_sibling_component(node: Node, component_class: Object) -> Node:
	if not node:
		push_error("get_sibling_component called with null node")
		return null
	var parent = node.get_parent()
	var sibling = parent.get_node_or_null(component_class.component)
	return sibling

# TODO: Move all those inside the components as already done for most.
static func get_persistent_game_state_component_or_die(node: Node) -> PersistentGameStateComponent:
	return get_or_die(node, PersistentGameStateComponent.component) as PersistentGameStateComponent

# Level components.
static func get_victory_loss_condition_component_or_die(node: Node) -> VictoryLossConditionComponent:
	return get_or_die(node, VictoryLossConditionComponent.component) as VictoryLossConditionComponent
