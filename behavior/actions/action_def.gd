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
	BLINK_TO,
	TELEPORT_AWAY,
	TELEPORT_TO,
}

@export var id: Id

func _init():
	skill_type = SkillType.ACTION

static func action_name(action_id: Id) -> String:
	return Id.keys()[action_id].capitalize()

func name() -> String:
	return Id.keys()[id].capitalize()

func _to_string() -> String:
	return name()
