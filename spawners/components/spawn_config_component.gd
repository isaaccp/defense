@tool
extends Node

class_name SpawnConfigComponent

const component = &"SpawnConfigComponent"

@export_group("Optional")
# Provide the config you want to override over the spawner you are
# configuring. Otherwise the one in the scene will be used.
@export var spawn_provider_config: SpawnProviderConfig
@export var spawn_placer_config: SpawnPlacerConfig
@export var spawn_position_config: SpawnPositionConfig

func _ready():
	if Engine.is_editor_hint():
		return
	var parent = get_parent()
	if spawn_provider_config:
		SpawnProviderComponent.get_or_die(parent).config = spawn_provider_config
	if spawn_placer_config:
		SpawnPlacerComponent.get_or_die(parent).config = spawn_placer_config
	if spawn_position_config:
		SpawnPositionComponent.get_or_die(parent).config = spawn_position_config

static func get_or_null(node: Node) -> SpawnConfigComponent:
	return Component.get_or_null(node, component) as SpawnConfigComponent

static func get_or_die(node: Node) -> SpawnConfigComponent:
	var component = get_or_null(node)
	assert(component)
	return component
