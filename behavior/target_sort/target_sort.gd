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
	# For sorts that allow sorting an Array of actors, can only
	# be invoked by targets of type Target.ACTOR or Target.ACTORS.
	ACTOR,
	# For sorts that allow sorting an Array of Vector2, can only
	# be invoked by targets of type Target.POSITION.
	POSITION,
}

@export var id: Id
@export var types: Array[Type]

func name() -> String:
	return Id.keys()[id].capitalize()
