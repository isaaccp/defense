extends Control

class_name Screen

var ui_layer: UILayerBase

func _setup_screen(_ui_layer: UILayerBase) -> void:
	ui_layer = _ui_layer

# Invoked by ui_layer when showing a screen.
func _on_show(_info: Dictionary):
	pass

# Invoked by ui_layer when hiding a screen.
func _on_hide():
	pass
