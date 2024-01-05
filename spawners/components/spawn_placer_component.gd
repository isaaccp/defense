@tool
extends Node2D

class_name SpawnPlacerComponent

const component = &"SpawnPlacerComponent"

@export_group("Required")
@export var spawn_provider_component: SpawnProviderComponent
@export var spawn_position_component: SpawnPositionComponent
@export var config: SpawnPlacerConfig

# Must be set from the parent.
var placement_node: Node2D
var finished = false

func run():
	_place_loop.call_deferred()

func _place_loop():
	var spawned = 0
	while is_instance_valid(self) and spawned < config.placement_amount:
		var spawn = spawn_provider_component.new_spawn()
		var spawn_pos = spawn_position_component.new_spawn_position()
		placement_node.add_child(spawn)
		spawn.global_position = global_position + spawn_pos
		if spawn.has_method("run"):
			spawn.run()
		else:
			print("Unrunnable spawn: %s", spawn.name)
		spawned += 1
		await get_tree().create_timer(config.placement_interval, false).timeout

static func get_or_null(node: Node) -> SpawnPlacerComponent:
	return Component.get_or_null(node, component) as SpawnPlacerComponent

static func get_or_die(node: Node) -> SpawnPlacerComponent:
	var component = get_or_null(node)
	assert(component)
	return component
