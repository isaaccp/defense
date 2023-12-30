extends UILayerBase

class_name GameplayUILayer

@export_group("Internal")
@export var character_selection_screen: Screen
@export var hud: Hud

signal character_selection_screen_selection_ready(character_selections: Array[Enum.CharacterId])

func _on_character_selection_screen_selection_ready(character_selections: Array[Enum.CharacterId]):
	character_selection_screen_selection_ready.emit(character_selections)
