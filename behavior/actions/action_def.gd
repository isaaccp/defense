extends Resource

class_name ActionDef

enum Id {
	UNSPECIFIED,
	MOVE_TO,
	SWORD_ATTACK,
}

@export var id: Id

static func name(action_id: Id) -> String:
	return Id.keys()[action_id].capitalize()
	
func _to_string() -> String:
	return name(id)
