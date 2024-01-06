@tool

extends Actor

class_name Spawner

@export var placement_node: Node2D

var placer: SpawnPlacerComponent

func _ready():
	if Engine.is_editor_hint():
		_on_ready_editor()
		return
	placer = SpawnPlacerComponent.get_or_die(self)
	if get_parent() == get_tree().root:
		var bait = Node2D.new()
		bait.name = "Bait"
		add_child(bait)
		var gc = load("res://character/playable_characters/godric_the_knight.tres")
		var character = gc.make_character_body()
		bait.add_child(character)
		character.global_position = Vector2(100, 100)
		var spawns = Node2D.new()
		spawns.name = "Spawns"
		add_child(spawns)
		placement_node = spawns
		if not placer.config:
			placer.config = SpawnPlacerConfig.new()
			placer.config.amount = 100
			placer.config.interval = 3
			placer.config.initial_delay = 1
		position = get_viewport_rect().size / 2.0
		placer.placement_node = placement_node
		placer.run()
		return

	assert(placement_node, "placement_node not set")
	placer.placement_node = placement_node

func finished():
	return placer.finished

func _on_ready_editor():
	var spawners_node = get_parent()
	var ysorted_node = spawners_node.get_parent()
	var enemies_node = ysorted_node.get_node("Enemies")
	placement_node = enemies_node
	if _get_configuration_warnings().size() != 0:
		var config_component = load("res://spawners/components/spawn_config_component.tscn").instantiate()
		add_child(config_component)
		config_component.owner = get_tree().edited_scene_root

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
			if not config_component or not config_component.get(config_name):
				var article = "the" if config_component else "a"
				warnings.append("This Spawner requires %s child SpawnConfigComponent to provide %s" % [article, config_name])

