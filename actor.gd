extends Node2D

class_name Actor

# Base class for all component-based runnable actors.

@export var actor_name: String
var running = false

# Called when level is starting.
func run():
	if running:
		assert(false, "run() called twice for actor %s" % actor_name)
	running = true
	for child in get_children():
		if child.get("component") != null:
			if child.has_method("run"):
				child.run()
