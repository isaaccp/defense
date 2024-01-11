extends UILayerBase

class_name GameplayUILayer

# TODO: Unclear if this scene provides a lot of value, maybe I should
# add the scene directly in gameplay so I can connect directly to signals
# instead of having to proxy them through here.
@export_group("Internal")
@export var character_selection_screen: CharacterSelectionScreen
@export var hud: Hud

signal character_selection_screen_selection_ready(character_selections: Array[Enum.CharacterId])
signal behavior_modified(character_idx: int, behavior: StoredBehavior)
signal restart_requested

func _ready():
	super()

func _on_character_selection_screen_selection_ready(character_selections: Array[Enum.CharacterId]):
	character_selection_screen_selection_ready.emit(character_selections)

func _on_behavior_modified(character_idx: int, behavior: StoredBehavior):
	behavior_modified.emit(character_idx, behavior)

func _on_hud_restart_requested():
	restart_requested.emit()

func _on_hud_view_log_requested(logging_component):
	show_log_viewer(logging_component)

func show_log_viewer(logging_component: LoggingComponent):
	%LogViewer.show_log(logging_component)

func hide_log_viewer():
	%LogViewer.reset()
	%LogViewer.hide()

func _on_hud_upgrade_window_requested(character):
	show_upgrade_window(character)

func show_upgrade_window(character: Character):
	show_screen(%UpgradeCharacterScreen)
	%UpgradeCharacterScreen.show_upgrades(character)
	hud.hide()
