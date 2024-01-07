@tool
extends ParamSkill

class_name ActionDef

enum Id {
	UNSPECIFIED,
	MOVE_TO,
	SWORD_ATTACK,
	BOW_ATTACK,
	CHARGE,
	MULTI_SHOT,
	HEAL,
	HOLD_PERSON,
	BLINK_AWAY,
	BLINK_TO,
	TELEPORT_AWAY,
	TELEPORT_TO,
}

# Used when something needs to explicitly mean no action.
# Making it not empty so it's unique to action, it's obvious what went
# wrong if it shows up, etc.
const NoAction = &"__no_action__"

@export var id: Id
## Script implementing this action.
@export var action_script: GDScript
## Types of target that this action supports. The action script must be able
## to handle all the target types declared here. It is used by the UI to
## prevent invalid configurations.
@export var supported_target_types: Array[Target.Type]

func _init():
	skill_type = SkillType.ACTION

static func action_name(action_id: Id) -> String:
	return Id.keys()[action_id].capitalize()

func name() -> String:
	return Id.keys()[id].capitalize()

func compatible_with_target(target_type: Target.Type) -> bool:
	return target_type in supported_target_types

func supported_target_types_str() -> String:
	var supported_targets = supported_target_types.map(func(t): return Target.target_type_str(t))
	return ",".join(supported_targets)
