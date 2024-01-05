extends Node2D

class_name Actor

# Base class for all component-based runnable actors.

@export var actor_name: String

func run():
	for child in get_children():
		if child.get("component") != null:
			if child.has_method("run"):
				child.run()
