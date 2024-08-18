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

func get_component_or_die(component_class: Object) -> Node:
	var component = get_component_or_null(component_class)
	assert(component, "Couldn't find wanted component")
	return component

func get_component_or_null(component_class: Object) -> Node:
	assert(component_class.component)
	return Component.get_or_null(self, component_class.component)

## Calls run in all components.
func run():
	if Engine.is_editor_hint():
		return
	if running:
		assert(false, "run() called twice for actor %s" % actor_name)
	running = true
	for child in get_children():
		if child.get("component") != null:
			if child.has_method("run"):
				child.run()

## Calls stop in all components.
func stop():
	if not running:
		assert(false, "stop() called before running for actor %s" % actor_name)
	if stopped:
		assert(false, "stop() called twice for actor %s" % actor_name)
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
	var hurtbox = get_component_or_die(HurtboxComponent)
	return hurtbox.global_position
