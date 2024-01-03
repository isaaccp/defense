extends Resource

class_name GameMode

enum OnlineType {
	LOCAL,
	CONNECT,
}

@export var online: OnlineType
@export var level_provider: LevelProvider
@export var fallback_local_nakama = false

func is_local():
	return online == OnlineType.LOCAL

func is_multiplayer():
	return online == OnlineType.CONNECT
