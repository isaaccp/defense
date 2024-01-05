@tool
extends Node

class_name SpawnProviderComponent

const component = &"SpawnProviderComponent"

# Provides spawns to place.

# Make this fancier (e.g. multiple enemies, probabilities, etc).
@export var config: SpawnProviderConfig

func new_spawn() -> Node2D:
	return config.spawn.instantiate() as Node2D

static func get_or_null(node: Node) -> SpawnProviderComponent:
	return Component.get_or_null(node, component) as SpawnProviderComponent

static func get_or_die(node: Node) -> SpawnProviderComponent:
	var component = get_or_null(node)
	assert(component)
	return component
