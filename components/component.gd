extends RefCounted

class_name Component

static func get_or_die(node: Node, component_name: String) -> Node:
	var component = get_or_null(node, component_name)
	assert(component, "Couldn't find wanted component")
	return component

static func get_or_null(node: Node, component_name: String) -> Node:
	return node.get_node_or_null(component_name)

static func get_health_component_or_die(node: Node) -> HealthComponent:
	var health_component = get_or_die(node, HealthComponent.component) as HealthComponent
	if not health_component:
		assert(false)
	return health_component
	
static func get_behavior_component_or_die(node: Node) -> BehaviorComponent:
	var behavior_component = get_or_die(node, BehaviorComponent.component) as BehaviorComponent
	if not behavior_component:
		assert(false)
	return behavior_component
