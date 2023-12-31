@tool
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

static func make(action_id: Id) -> ActionDef:
	var action = ActionDef.new()
	action.id = action_id
	return action

func _to_string() -> String:
	return name(id)
