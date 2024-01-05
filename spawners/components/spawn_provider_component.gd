@tool
extends Node

class_name SpawnProviderComponent

const component = &"SpawnProviderComponent"

# Provides spawns to place.

# Make this fancier (e.g. multiple enemies, probabilities, etc).
@export var config: SpawnProviderConfig

func new_spawn() -> Node2D:
	var spawn = config.spawn.instantiate() as Node2D
	return spawn

static func get_or_null(node: Node) -> SpawnProviderComponent:
	return Component.get_or_null(node, component) as SpawnProviderComponent

static func get_or_die(node: Node) -> SpawnProviderComponent:
	var c = get_or_null(node)
	assert(c)
	return c
