extends RefCounted

class_name Component

static func get_or_die(node: Node, component_name: String) -> Node:
	var component = get_or_null(node, component_name)
	assert(component, "Couldn't find wanted component")
	return component

static func get_or_null(node: Node, component_name: String) -> Node:
	return node.get_node_or_null(component_name)

static func get_health_component_or_die(node: Node) -> HealthComponent:
	var component = get_or_die(node, HealthComponent.component) as HealthComponent
	if not component:
		assert(false)
	return component
	
static func get_behavior_component_or_die(node: Node) -> BehaviorComponent:
	var component = get_or_die(node, BehaviorComponent.component) as BehaviorComponent
	if not component:
		assert(false)
	return component

static func get_status_component_or_die(node: Node) -> StatusComponent:
	var component = get_or_die(node, StatusComponent.component) as StatusComponent
	if not component:
		assert(false)
	return component
