extends Resource

class_name GameMode

enum OnlineType {
	LOCAL,
	CONNECT,
}

@export var online: OnlineType
@export var level_provider: LevelProvider
@export var fallback_local_nakama = false
# If set, force usage of this behavior library during the game.
# Useful during development to be able to quickly have a good
# behavior library to set behaviors from.
@export var dev_behavior_library: BehaviorLibrary

func is_local():
	return online == OnlineType.LOCAL

func is_multiplayer():
	return online == OnlineType.CONNECT
