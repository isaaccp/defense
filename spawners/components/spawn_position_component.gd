@tool
extends Node2D

class_name SpawnPositionComponent

const component = &"SpawnPositionComponent"

@export var config: SpawnPositionConfig


func new_spawn_position() -> Vector2:
	assert(config.pattern != SpawnPositionConfig.SpawnPattern.UNSPECIFIED)
	match config.pattern:
		SpawnPositionConfig.SpawnPattern.CONSTANT:
			return position
	assert(false, "Should not happen")
	return Vector2.ZERO

static func get_or_null(node: Node) -> SpawnPositionComponent:
	return Component.get_or_null(node, component) as SpawnPositionComponent

static func get_or_die(node: Node) -> SpawnPositionComponent:
	var c = get_or_null(node)
	assert(c)
	return c
