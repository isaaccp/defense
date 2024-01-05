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
}

@export var id: Id

func _init():
	skill_type = SkillType.ACTION

static func action_name(action_id: Id) -> String:
	return Id.keys()[action_id].capitalize()

static func make(action_id: Id) -> ActionDef:
	var action = ActionDef.new()
	action.id = action_id
	return action

func name() -> String:
	return action_name(id)

func _to_string() -> String:
	return action_name(id)
