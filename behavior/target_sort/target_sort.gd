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
	## For sorts that allow sorting an Array of actors, can only
	## be invoked by targets of type Target.ACTOR or Target.ACTORS.
	ACTOR,
	## For sorts that allow sorting an Array of Vector2, can
	## be invoked by targets of type Target.POSITION, Target.ACTOR
	## or Target.ACTORS.
	POSITION,
}

@export var id: Id
# TODO: Still need to make the UI respect this.
## Type of sort supported. Determines which type of
## target selectors can use this sort and makes UI prevent
## bad combinations.
@export var type: Type

func compatible_with_target(target_type: Target.Type) -> bool:
	return target_type in supported_target_types()

func supported_target_types() -> Array[Target.Type]:
	match type:
		Type.ACTOR:
			return [Target.Type.ACTOR, Target.Type.ACTORS]
		Type.POSITION:
			return [Target.Type.POSITION, Target.Type.ACTOR, Target.Type.ACTORS]
	assert(false, "Should not happen")
	return []

func supported_target_types_str() -> String:
	var supported_targets = supported_target_types().map(func(t): return Target.target_type_str(t))
	return ",".join(supported_targets)

func name() -> String:
	return Id.keys()[id].capitalize()

# TODO: Add a description and show it somewhere in the UI.
