extends Resource

class_name ActionDef

enum Id {
	UNSPECIFIED,
	MOVE_TO,
	SWORD_ATTACK,
}

@export var id: Id

func _to_string() -> String:
	return Id.keys()[id]
