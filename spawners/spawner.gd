@tool

extends Actor

class_name Spawner

@export var placement_node: Node2D

func _ready():
	var placer = SpawnPlacerComponent.get_or_die(self)
	placer.placement_node = placement_node

func _get_configuration_warnings():
	var warnings = PackedStringArray()
	# Ideally we would make it so we have two kinds of warnings:
	#  * internal component plumbing
	#  * the ones we have below intended for when instantiating a spawner in a level
	# Internal warnings would be added here, and returned even in the spawner scene.
	# The other ones are added below and returned only in the tree.
	if not get_parent() is Node2D:
		return warnings
	if not placement_node:
		warnings.append("Must set placement_node")
	var config_component = SpawnConfigComponent.get_or_null(self)
	_component_warnings(warnings, config_component, "spawn_placer_config", SpawnPlacerComponent.get_or_null(self), "SpawnPlacerComponent")
	_component_warnings(warnings, config_component, "spawn_provider_config", SpawnProviderComponent.get_or_null(self), "SpawnProviderComponent")
	_component_warnings(warnings, config_component, "spawn_position_config", SpawnPositionComponent.get_or_null(self), "SpawnPositionComponent")
	return warnings

func _component_warnings(warnings: PackedStringArray, config_component: SpawnConfigComponent, config_name: String, component: Node, component_name: String):
	if not component:
		warnings.append("Missing %s" % component_name)
	else:
		if not component.config:
			if not config_component.get(config_name):
				var article = "the" if config_component else "a"
				warnings.append("This Spawner requires %s child SpawnConfigComponent to provide %s" % [article, config_name])

