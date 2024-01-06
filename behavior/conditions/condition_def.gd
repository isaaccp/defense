@tool
extends ParamSkill

class_name ConditionDef

enum Id {
	UNSPECIFIED,
	ALWAYS,
	TARGET_HEALTH,
	ONCE,
	TARGET_DISTANCE,
	TIMES,
}

# Type of condition.
enum Type {
	UNSPECIFIED,
	## Condition that can be applied regardless of target.
	## E.g., Always, Once, Every 5 seconds.
	ANY,
	# Note that this condition makes sense for ACTORS too, but needs an extra bit
	# for whether you want All, Any, None to comply with the condition.
	# That doesn't exist yet.
	## Condition that can be applied to targets of Target.Type.ACTOR as a filter.
	## E.g., "target health < X".
	TARGET_ACTOR,
	## Condition that can be applied to the actor running the check.
	## In general the same conditions as for Target.ACTOR make sense, it's just
	## the check subject which changes (target vs self). Some may not make sense
	## e.g. "distance to self" and they'll be provided by different Skills
	## possibly using the same code.
	SELF,
	## Condition that can be evaluated globally, but unlike "ANY", requires
	## world knowledge. E.g. number of characters/enemies left.
	GLOBAL,
}

@export var id: Id
@export var type: Type

func name() -> String:
	return Id.keys()[id].capitalize()

func compatible_with_target(target_type: Target.Type) -> bool:
	if type in [Type.ANY, Type.GLOBAL, Type.SELF]:
		return true
	if type == Type.TARGET_ACTOR:
		return target_type == Target.Type.ACTOR
	return false

func supported_target_types_str() -> String:
	if type in [Type.ANY, Type.GLOBAL, Type.SELF]:
		return "All"
	if type == Type.TARGET_ACTOR:
		return "Actor"
	return "<fix me>"

func full_description():
	return "%s\nSupported Target Types: %s" % [name(), supported_target_types_str()]
