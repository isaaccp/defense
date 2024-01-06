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
	# Can be applied regardless of target.
	ANY,
	# Can be applied to targets of Target.Type.ACTOR as a filter.
	TARGET_NODE,
	# Condition applies to self (e.g. my health > X).
	SELF,
	# Some global condition that doesn't apply to targets, e.g.
	# number of characters/enemies left.
	GLOBAL,
}

@export var id: Id
@export var type: Type

func name() -> String:
	return Id.keys()[id].capitalize()
