extends Node2D

class_name Actor

# Base class for all component-based runnable actors.

@export var actor_name: String
var running = false

func get_component_or_die(component_class: Object) -> Node:
	var component = get_component_or_null(component_class)
	assert(component, "Couldn't find wanted component")
	return component

func get_component_or_null(component_class: Object) -> Node:
	assert(component_class.component)
	return Component.get_or_null(self, component_class.component)

# Called when level is starting.
func run():
	if running:
		assert(false, "run() called twice for actor %s" % actor_name)
	running = true
	for child in get_children():
		if child.get("component") != null:
			if child.has_method("run"):
				child.run()
