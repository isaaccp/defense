@tool
extends ParamSkill

class_name ActionDef

# Used when something needs to explicitly mean no action.
# Making it not empty so it's unique to action, it's obvious what went
# wrong if it shows up, etc.
const NoAction = &"__no_action__"

## How an AoE action's shape is positioned in the world. Read by targeting
## helpers (e.g. Can Hit Enemies, Most Enemies Position) to know what
## placements are candidates. Rotation, when it matters, is auto-derived
## from shape symmetry: a circular shape with zero aoe_offset is treated as
## rotationally invariant (one candidate); anything else enumerates one
## rotation per nearby enemy (toward that enemy).
enum AoePlacement {
	## Not an AoE action.
	NONE,
	## Shape at caster's position.
	SELF,
	## Shape anywhere within max_distance of the caster (e.g. ranged AoE).
	POSITION_FREE,
}

## Script implementing this action.
@export var action_script: GDScript
## Types of target that this action supports. The action script must be able
## to handle all the target types declared here. It is used by the UI to
## prevent invalid configurations.
@export var supported_target_types: Array[Target.Type]
## Attack type, only set for attacks.
@export var attack_type: AttackType
## Action tags.
@export var tags: Array[ActionTag.Tag]

## AoE shape applied to the action's scene at spawn time (overrides any
## CollisionShape2D shape declared in the .tscn). Null = not an AoE.
@export var aoe_shape: Shape2D
## How aoe_shape is positioned. Drives candidate generation in targeting
## helpers — see AoePlacement.
@export var aoe_placement: AoePlacement = AoePlacement.NONE
## Local-space offset from the placement origin to the shape's center.
## SELF_ORIENTED actions typically use this to put the shape in front of
## the caster after rotation.
@export var aoe_offset: Vector2 = Vector2.ZERO

func _init():
	skill_type = SkillType.ACTION

func name() -> String:
	return skill_name

func compatible_with_target(target_type: Target.Type) -> bool:
	# Check if target_Type is in supported_target_Types.
	# Also allow SELF to satisfy ACTOR supported_target_type.
	return (target_type in supported_target_types) or (target_type == Target.Type.SELF and Target.Type.ACTOR in supported_target_types)

func supported_target_types_str() -> String:
	var supported_targets = supported_target_types.map(func(t): return Target.target_type_str(t))
	return ",".join(supported_targets)

func description() -> String:
	# TODO: Figure out a cleaner way to do this. As of now using duck
	# typing to not create a loop with Action dependency.
	var action = action_script.new()
	action.def = self
	return action.full_description()
