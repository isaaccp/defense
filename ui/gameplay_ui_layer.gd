extends UILayerBase

class_name GameplayUILayer

@export_group("Internal")
@export var character_selection_screen: Screen
@export var hud: Hud

signal character_selection_screen_selection_ready(character_selections: Array[Enum.CharacterId])
signal readiness_updated(character_idx: int, ready: bool)

func _on_character_selection_screen_selection_ready(character_selections: Array[Enum.CharacterId]):
	character_selection_screen_selection_ready.emit(character_selections)

func _on_readiness_updated(character_idx: int, ready: bool):
	readiness_updated.emit(character_idx, ready)
