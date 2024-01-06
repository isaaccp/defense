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
## Types of sort supported. Determines which types of
## target selectors can use this sort and makes UI prevent
## bad combinations.
@export var types: Array[Type]

func name() -> String:
	return Id.keys()[id].capitalize()
