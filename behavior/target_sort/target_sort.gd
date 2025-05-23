@tool
extends Skill

class_name TargetSort

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

## Type of sort supported. Determines which type of
## target selectors can use this sort and makes UI prevent
## bad combinations.
@export var type: Type
@export var sorter_script: GDScript
@export_multiline var description_text: String = "<missing description>"

func _init():
	skill_type = SkillType.TARGET_SORT

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

# TODO: Once all migrated, maybe rename skill_name as name and remove those.
func name() -> String:
	return skill_name

func description():
	return description_text
