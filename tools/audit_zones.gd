extends SceneTree

# Headless zone-coverage audit — no render, pure calculation. Reports:
#  - % of the stage area covered by declared Zones
#  - any OPEN/ENCLOSED zone with no DecorationScatter child that isn't flagged
#    deliberately_bare (an undecorated zone that should be decorated)
#
# Usage: godot --headless --path . -s tools/audit_zones.gd -- <stage_scene>

const STAGE_SIZE := Vector2(960, 540)
const CELL := 16
const MIN_COVERAGE := 90.0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("Usage: godot --headless --path . -s tools/audit_zones.gd -- <stage_scene>")
		quit(1)
		return
	var scene_path: String = args[0]
	if not scene_path.begins_with("res://"):
		scene_path = "res://" + scene_path
	var packed := load(scene_path) as PackedScene
	if not packed:
		push_error("Could not load: %s" % scene_path)
		quit(1)
		return
	# instantiate() builds the node tree without running _ready — enough to
	# read Zone configs and child structure.
	var scene := packed.instantiate()

	var zones: Array = []
	_collect(scene, zones)

	var cols := int(ceil(STAGE_SIZE.x / CELL))
	var rows := int(ceil(STAGE_SIZE.y / CELL))
	var covered := {}
	var problems: Array[String] = []
	var kind_names := ["OPEN", "ENCLOSED", "SOLID"]

	print("=== Zone audit: %s ===" % scene_path)
	if zones.is_empty():
		print("  (no Zone nodes found)")
	for z in zones:
		var zone: Zone = z
		var kind_name: String = kind_names[zone.kind]
		var has_scatter := false
		for c in zone.get_children():
			if c is DecorationScatter:
				has_scatter = true
				break
		var rect_str := "(no area)"
		if zone.area and zone.area.get("rect") is Rect2:
			var r: Rect2 = zone.area.get("rect")
			rect_str = "(%d,%d %dx%d)" % [r.position.x, r.position.y, r.size.x, r.size.y]
			var cx0 := int(floor(r.position.x / CELL))
			var cx1 := int(ceil(r.end.x / CELL))
			var cy0 := int(floor(r.position.y / CELL))
			var cy1 := int(ceil(r.end.y / CELL))
			for cx in range(cx0, cx1):
				for cy in range(cy0, cy1):
					if cx >= 0 and cx < cols and cy >= 0 and cy < rows:
						covered[Vector2i(cx, cy)] = true

		var note := ""
		if zone.kind != Zone.Kind.SOLID and not has_scatter and not zone.deliberately_bare:
			note = "  <-- UNDECORATED"
			problems.append("%s: %s zone has no scatter and isn't deliberately_bare" % [zone.name, kind_name])
		elif zone.deliberately_bare:
			note = "  (deliberately bare)"
		print("  %-20s %-9s %-22s scatter=%s%s" % [zone.name, kind_name, rect_str, has_scatter, note])

	var coverage := 0.0
	if cols * rows > 0:
		coverage = float(covered.size()) / float(cols * rows) * 100.0
	print("Coverage: %.1f%% of stage" % coverage)
	if coverage < MIN_COVERAGE:
		problems.append("coverage %.1f%% is below %.0f%%" % [coverage, MIN_COVERAGE])

	print("")
	if problems.is_empty():
		print("OK - every zone identified, decorated or deliberately bare, coverage >= %.0f%%" % MIN_COVERAGE)
	else:
		print("PROBLEMS (%d):" % problems.size())
		for p in problems:
			print("  - " + p)
	quit(0 if problems.is_empty() else 1)

func _collect(node: Node, out: Array) -> void:
	if node is Zone:
		out.append(node)
	for c in node.get_children():
		_collect(c, out)
