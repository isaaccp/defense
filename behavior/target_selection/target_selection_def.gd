extends Resource

class_name TargetSelectionDef

enum Id {
	UNSPECIFIED,
	CLOSEST_ENEMY,
}

@export var id: Id

func _to_string() -> String:
	return Id.keys()[id]
