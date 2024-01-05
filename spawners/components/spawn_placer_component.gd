@tool
extends Node2D

class_name SpawnPlacerComponent

const component = &"SpawnPlacerComponent"

@export_group("Required")
@export var spawn_provider_component: SpawnProviderComponent
@export var spawn_position_component: SpawnPositionComponent
@export var config: SpawnPlacerConfig

@export_group("Optional")
# For animations, etc.
@export var spawn_animation_component: SpawnAnimationControllerComponent

# Must be set from the parent.
var placement_node: Node2D
var finished = false

func run():
	assert(config.interval > 0.5, "Minimum spawn interval")
	_place_loop.call_deferred()

func _place_loop():
	var spawned = 0
	await get_tree().create_timer(config.initial_delay, false).timeout
	if is_instance_valid(self):
		if spawn_animation_component:
			await spawn_animation_component.on_spawning_start()

	while is_instance_valid(self) and spawned < config.amount:
		if spawn_animation_component:
			spawn_animation_component.on_spawn()
		await get_tree().create_timer(0.5, false).timeout
		var spawn = spawn_provider_component.new_spawn()
		var spawn_pos = spawn_position_component.new_spawn_position()
		placement_node.add_child(spawn)
		spawn.global_position = global_position + spawn_pos
		if spawn.has_method("run"):
			spawn.run()
		else:
			print("Unrunnable spawn: %s", spawn.name)
		spawned += 1
		await get_tree().create_timer(config.interval-0.5, false).timeout

	if spawn_animation_component:
		await spawn_animation_component.on_spawning_end()

static func get_or_null(node: Node) -> SpawnPlacerComponent:
	return Component.get_or_null(node, component) as SpawnPlacerComponent

static func get_or_die(node: Node) -> SpawnPlacerComponent:
	var component = get_or_null(node)
	assert(component)
	return component
