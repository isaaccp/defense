extends Container

class_name HudStatusDisplay

@export var status_library: StatusLibrary

var hud_status_icon_scene = preload("res://ui/hud_status_icon.tscn")

func clear():
	for child in get_children():
		child.queue_free()

func _add_icon(icon: Texture, tooltip: String):
	var status_icon = hud_status_icon_scene.instantiate() as HudStatusIcon
	status_icon.initialize(icon, tooltip)
	add_child(status_icon)

func add_status(status_id: StatusDef.Id):
	var status = status_library.get_status(status_id)
	_add_icon(status.icon, status.description)
