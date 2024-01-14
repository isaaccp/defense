@tool
extends Resource

# Resource class to store lists of behaviors.
# The main use case is to allow players to store behaviors
# they like and restore them quickly later. This will be
# especially useful if the game is roguelike, but still
# necessary otherwise for e.g. quickly trying different
# strategies without having to start from scratch.
# TODO: Add a way to easily check if the current skill tree
# supports a behavior (i.e., all required skills are unlocked).
class_name BehaviorLibrary

@export var behaviors: Array[StoredBehavior]

# behavior should have a name and not exist in the library.
func add(behavior: StoredBehavior):
	assert(not behavior.name.is_empty())
	assert(not behaviors.any(func(b): return b.name == behavior.name))
	behaviors.append(behavior)

func replace(behavior: StoredBehavior):
	assert(not behavior.name.is_empty())
	for i in range(behaviors.size()):
		var b = behaviors[i]
		if b.name == behavior.name:
			behaviors[i] = behavior
			return
	assert(false, "Could not find behavior to replace")

func delete(name: String):
	for i in range(behaviors.size()):
		var b = behaviors[i]
		if b.name == name:
			behaviors.remove_at(i)
			return

func contains(name: String) -> bool:
	return behaviors.any(func(b): return b.name == name)
