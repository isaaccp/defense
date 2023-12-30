extends Resource

class_name TargetSelectionDef

enum Id {
	UNSPECIFIED,
	CLOSEST_ENEMY,
}

@export var id: Id

static func name(action_id: Id) -> String:
	return Id.keys()[action_id].capitalize()
	
func _to_string() -> String:
	return name(id)
