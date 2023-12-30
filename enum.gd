extends Object

class_name Enum

enum CharacterId {
	UNSPECIFIED,
	KNIGHT,
}

static func character_id_string(id: CharacterId) -> String:
	return CharacterId.keys()[id].capitalize()
