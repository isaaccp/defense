@tool
extends ParamSkill

class_name TargetSelectionDef

enum Id {
	UNSPECIFIED,
	CLOSEST_ENEMY,
	TOWER,
	SELF,
	SELF_OR_ALLY,
	ALLY,
	FARTHEST_ENEMY,
}

@export var id: Id
@export var type: Target.Type

static func target_selection_name(target_selection_id: Id) -> String:
	return Id.keys()[target_selection_id].capitalize()

func name() -> String:
	return target_selection_name(id)

func _to_string() -> String:
	return target_selection_name(id)
