extends Node2D

class_name Character

@export_group("debug")
@export var id: Enum.CharacterId
@export var idx: int
@export var peer_id: int

func short_name() -> String:
	return "%s (%d)" % [Enum.character_id_string(id), idx]
