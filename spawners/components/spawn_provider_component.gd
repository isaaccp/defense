@tool
extends Node

class_name SpawnProviderComponent

const component = &"SpawnProviderComponent"

# Provides spawns to place.
const enemy_scene = preload("res://enemies/enemy.tscn")

# Make this fancier (e.g. multiple enemies, probabilities, etc).
@export var config: SpawnProviderConfig

func new_spawn() -> Node2D:
	var spawn: Node2D
	if config.spawn:
		spawn = config.spawn.instantiate() as Enemy
	else:
		spawn = enemy_scene.instantiate() as Enemy
		spawn.config = config.spawn_enemy_config
	return spawn

static func get_or_null(node: Node) -> SpawnProviderComponent:
	return Component.get_or_null(node, component) as SpawnProviderComponent

static func get_or_die(node: Node) -> SpawnProviderComponent:
	var c = get_or_null(node)
	assert(c)
	return c
