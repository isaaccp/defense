@tool
extends Resource

class_name TargetSelectionDef

enum Id {
	UNSPECIFIED,
	CLOSEST_ENEMY,
	TOWER,
	SELF,
}

@export var id: Id

static func target_selection_name(target_selection_id: Id) -> String:
	return Id.keys()[target_selection_id].capitalize()

static func make(target_selection_id: Id) -> TargetSelectionDef:
	var target_selection = TargetSelectionDef.new()
	target_selection.id = target_selection_id
	return target_selection

func name() -> String:
	return target_selection_name(id)

func _to_string() -> String:
	return target_selection_name(id)
