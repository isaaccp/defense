extends SceneTree

# Dumps a human-readable summary of a level/stage scene. Usage:
#   godot --headless -s tools/inspect_stage.gd -- <scene_path>
#
# Loads the scene via Godot so node references, exports, and inheritance
# resolve correctly. The scene is instantiated detached from the tree, so
# _ready() does not fire and the inspector has no gameplay side effects.

func _initialize():
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("Usage: godot --headless -s tools/inspect_stage.gd -- <scene_path>")
		print("  e.g. tools/inspect_stage.gd -- res://levels/stages/forest_ambush.tscn")
		quit(1)
		return
	var path := args[0] as String
	if not path.begins_with("res://"):
		path = "res://" + path
	var packed := load(path) as PackedScene
	if not packed:
		push_error("Could not load: %s" % path)
		quit(1)
		return
	var scene := packed.instantiate()
	_inspect(scene, path)
	scene.free()
	quit(0)

func _inspect(scene: Node, path: String) -> void:
	print("=== %s ===" % path)
	print("  Bounds: 960x540 (16x16 tiles)")
	_print_section("StartingPositions", _format_children_positions(scene.get_node_or_null("StartingPositions")))
	_print_section("Towers", _format_children_positions(scene.get_node_or_null("YSorted/Towers")))
	_print_section("Enemies", _format_children_positions(scene.get_node_or_null("YSorted/Enemies")))
	_print_section("Characters", _format_children_positions(scene.get_node_or_null("YSorted/Characters")))
	_print_section("Decoration", _format_decoration(scene.get_node_or_null("YSorted/Decoration")))
	_print_section("Spawners", _format_spawners(scene.get_node_or_null("YSorted/Spawners")))
	_print_section("PlacementZones", _format_placement_zones(scene.get_node_or_null("PlacementComponent")))
	_print_section("VictoryLoss", _format_victory_loss(scene.get_node_or_null("VictoryLossConditionComponent")))

func _print_section(title: String, content: String) -> void:
	if content.is_empty():
		print("  %s: (none)" % title)
	else:
		print("  %s:" % title)
		for line in content.split("\n"):
			print("    %s" % line)

func _v(p: Vector2) -> String:
	return "(%d, %d)" % [round(p.x), round(p.y)]

func _format_children_positions(node: Node) -> String:
	if not node or node.get_child_count() == 0:
		return ""
	var lines: PackedStringArray = []
	for child in node.get_children():
		var label := child.name as String
		if child.scene_file_path:
			label = "%s [%s]" % [child.name, child.scene_file_path.get_file()]
		if child is Node2D:
			lines.append("%s @ %s" % [label, _v(child.position)])
		else:
			lines.append(label)
	return "\n".join(lines)

func _format_decoration(node: Node) -> String:
	if not node or node.get_child_count() == 0:
		return ""
	var counts := {}
	var xs := PackedFloat32Array()
	var ys := PackedFloat32Array()
	for child in node.get_children():
		var key := child.scene_file_path.get_file() if child.scene_file_path else (child.name as String)
		counts[key] = counts.get(key, 0) + 1
		if child is Node2D:
			xs.append(child.position.x)
			ys.append(child.position.y)
	var lines: PackedStringArray = []
	var keys := counts.keys()
	keys.sort()
	for k in keys:
		lines.append("%s: %d" % [k, counts[k]])
	if xs.size() > 0:
		var xmin := xs[0]; var xmax := xs[0]; var ymin := ys[0]; var ymax := ys[0]
		for i in xs.size():
			xmin = min(xmin, xs[i]); xmax = max(xmax, xs[i])
			ymin = min(ymin, ys[i]); ymax = max(ymax, ys[i])
		lines.append("bounds: x in [%d,%d], y in [%d,%d]" % [round(xmin), round(xmax), round(ymin), round(ymax)])
	return "\n".join(lines)

func _format_spawners(node: Node) -> String:
	if not node or node.get_child_count() == 0:
		return ""
	var lines: PackedStringArray = []
	for child in node.get_children():
		var label := "%s @ %s" % [child.name, _v(child.position)] if child is Node2D else child.name as String
		var cfg: SpawnConfigComponent = _find_spawn_config(child)
		if cfg:
			var enemy := "?"
			var prov = cfg.spawn_provider_config
			if prov:
				if prov.spawn:
					enemy = prov.spawn.resource_path.get_file()
				elif prov.spawn_enemy_config:
					enemy = prov.spawn_enemy_config.resource_path.get_file()
			var placer = cfg.spawn_placer_config
			if placer:
				label += "  enemy=%s amount=%s interval=%s delay=%s" % [
					enemy, placer.amount, placer.interval, placer.initial_delay,
				]
			else:
				label += "  enemy=%s" % enemy
		lines.append(label)
	return "\n".join(lines)

func _find_spawn_config(spawner: Node):
	for c in spawner.get_children():
		if c is SpawnConfigComponent:
			return c
	return null

func _format_placement_zones(pc: Node) -> String:
	if not pc:
		return ""
	var lines: PackedStringArray = []
	for child in pc.get_children():
		if not (child is Polygon2D):
			continue
		var rect := _polygon_bounds(child.polygon, child.position)
		lines.append("%s: rect (%d,%d)-(%d,%d)" % [
			child.name, rect.position.x, rect.position.y, rect.end.x, rect.end.y,
		])
	return "\n".join(lines)

func _polygon_bounds(poly: PackedVector2Array, offset: Vector2) -> Rect2:
	if poly.is_empty():
		return Rect2()
	var lo := poly[0]; var hi := poly[0]
	for p in poly:
		lo = Vector2(min(lo.x, p.x), min(lo.y, p.y))
		hi = Vector2(max(hi.x, p.x), max(hi.y, p.y))
	return Rect2(lo + offset, hi - lo)

func _format_victory_loss(vl: Node) -> String:
	if not vl:
		return ""
	var parts: PackedStringArray = []
	if vl.get("victory"):
		parts.append("victory=[%s]" % ", ".join(vl.victory.map(_victory_name)))
	if vl.get("loss"):
		parts.append("loss=[%s]" % ", ".join(vl.loss.map(_loss_name)))
	var t = vl.get("time")
	if t != null and t > 0:
		parts.append("time=%s" % t)
	return ", ".join(parts)

func _victory_name(v: int) -> String:
	return VictoryLossConditionComponent.VictoryType.keys()[v]

func _loss_name(v: int) -> String:
	return VictoryLossConditionComponent.LossType.keys()[v]
