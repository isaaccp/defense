@tool
extends Resource

class_name SpawnPositionConfig

enum SpawnPattern {
	UNSPECIFIED,
	CONSTANT,
}

@export var pattern: SpawnPattern
@export var offset = Vector2.ZERO
