extends Container

class_name HudRelicDisplay

var hud_status_icon_scene = preload("res://ui/hud_status_icon.tscn")

func clear():
	for child in get_children():
		child.queue_free()

func _add_icon(icon: Texture, tooltip: String):
	var relic_icon = hud_status_icon_scene.instantiate() as HudStatusIcon
	relic_icon.initialize(icon, tooltip)
	add_child(relic_icon)

func add_relic(relic: RelicDef):
	var tex = relic.icon
	if not tex:
		tex = PlaceholderTexture2D.new()
		tex.size = Vector2(32, 32)
	_add_icon(tex, "%s\n%s" % [relic.name, relic.description])
