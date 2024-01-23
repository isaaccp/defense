@tool
extends RefCounted

class_name Component

static func get_or_die(node: Node, component_name: String) -> Node:
	var component = get_or_null(node, component_name)
	assert(component, "Couldn't find wanted component")
	return component

static func get_or_null(node: Node, component_name: String) -> Node:
	return node.get_node_or_null(component_name)

# TODO: Move all those inside the components as already done for most.
static func get_logging_component_or_null(node: Node) -> LoggingComponent:
	return get_or_null(node, LoggingComponent.component) as LoggingComponent

static func get_logging_component_or_die(node: Node) -> LoggingComponent:
	var component = get_logging_component_or_null(node)
	if not component:
		assert(false)
	return component

static func get_status_component_or_die(node: Node) -> StatusComponent:
	var component = get_or_die(node, StatusComponent.component) as StatusComponent
	if not component:
		assert(false)
	return component

static func get_persistent_game_state_component_or_die(node: Node) -> PersistentGameStateComponent:
	var component = get_or_die(node, PersistentGameStateComponent.component) as PersistentGameStateComponent
	if not component:
		assert(false)
	return component

# Level components.
static func get_victory_loss_condition_component_or_die(node: Node) -> VictoryLossConditionComponent:
	var component = get_or_die(node, VictoryLossConditionComponent.component) as VictoryLossConditionComponent
	if not component:
		assert(false)
	return component
