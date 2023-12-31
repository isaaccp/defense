extends Control

class_name HudStatusIcon

func initialize(texture: Texture, tooltip: String) -> void:
	%TextureRect.texture = texture
	%TextureRect.tooltip_text = tooltip
