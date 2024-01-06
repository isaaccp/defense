@tool
extends Skill

class_name TargetSort

enum Id {
	UNSPECIFIED,
	CLOSEST_FIRST,
}

# Type of sort.
enum Type {
	UNSPECIFIED,
}

@export var id: Id
# Likely needed later when we have target types.
#@export var type: Type

func name() -> String:
	return Id.keys()[id].capitalize()
