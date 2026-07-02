@tool
extends Node2D

class_name Actor

# Base class for all component-based runnable actors.

@export var actor_name: String
# True if run() was called on this actor, but stopped hasn't been called yet.
var running = false
# True if stop() was called on this actor.
var stopped = false

# True if destroyed, subclasses should set it.
var destroyed = false
var visual_scale: float = 1.0

func get_component_or_die(component_class: Object) -> Node:
	var component = get_component_or_null(component_class)
	if not component:
		push_error("Couldn't find component '%s' on actor '%s'" % [component_class.component, actor_name])
	return component

func get_component_or_null(component_class: Object) -> Node:
	return Component.get_or_null(self, component_class.component)

## Calls run in all components.
func run():
	if Engine.is_editor_hint():
		return
	if running:
		push_error("run() called twice for actor '%s'" % actor_name)
		return
	running = true
	for child in get_children():
		if child.get("component") != null:
			if child.has_method("run"):
				child.run()

## Calls stop in all components.
func stop():
	if not running:
		push_error("stop() called before run() for actor '%s'" % actor_name)
		return
	if stopped:
		push_error("stop() called twice for actor '%s'" % actor_name)
		return
	stopped = true
	running = false
	for child in get_children():
		if child.get("component") != null:
			if child.has_method("stop"):
				child.stop()

## Global position that should be used when spawning attacks.
## For now, just spawn attacks from the middle of HurtboxComponent.
## Later we can have some explicit AttackComponent or similar
## that allows to set the position independently and e.g. even
## fancier stuff like showing different weapons.
func attack_position() -> Vector2:
	return $HurtboxComponent.get_target_position()
