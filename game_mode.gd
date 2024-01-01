extends Resource

class_name GameMode

enum OnlineType {
	LOCAL,
	CONNECT,
}

@export var online: OnlineType
@export var level_provider: LevelProvider

func is_local():
	return online == OnlineType.LOCAL

func is_multiplayer():
	return online == OnlineType.CONNECT
