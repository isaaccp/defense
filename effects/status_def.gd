extends EffectDef

class_name StatusDef

enum StatusType {
	NEUTRAL,
	WARD,
	BUFF,
	DEBUFF,
	DOT,
}

@export var status_type: StatusType = StatusType.NEUTRAL
@export var description: String
@export var icon: Texture2D
