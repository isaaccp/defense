extends SceneTree

# Renders a stage with every DecorationScatter zone outlined + labeled (name +
# kind), so zone coverage is auditable: is every part of the stage assigned to
# a zone, and is every OPEN field decorated?
#
# Usage:
#   godot --path . -s tools/render_zone_audit.gd -- <stage_scene> <output_png>
#   xvfb-run -a godot --path . -s tools/render_zone_audit.gd -- ...

const CANVAS := Vector2i(960, 540)
const WARMUP := 12

var _viewport: SubViewport
var _scene: Node
var _output_path: String
var _frames := 0
var _overlay_added := false

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("Usage: godot --path . -s tools/render_zone_audit.gd -- <stage_scene> <output_png>")
		quit(1)
		return
	var scene_path: String = args[0]
	_output_path = args[1]
	if not scene_path.begins_with("res://"):
		scene_path = "res://" + scene_path
	var packed := load(scene_path) as PackedScene
	if not packed:
		push_error("Could not load: %s" % scene_path)
		quit(1)
		return

	_viewport = SubViewport.new()
	_viewport.size = CANVAS
	_viewport.disable_3d = true
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)

	_scene = packed.instantiate()
	_viewport.add_child(_scene)

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == WARMUP and not _overlay_added:
		_overlay_added = true
		var zones: Array = []
		_collect_zones(_scene, zones)
		var overlay := _ZoneOverlay.new()
		overlay.zones = zones
		_viewport.add_child(overlay)
		return false
	if _frames < WARMUP + 4:
		return false
	var image := _viewport.get_texture().get_image()
	if not image or image.is_empty():
		push_error("Empty image — try xvfb-run.")
		return true
	image.save_png(_output_path)
	print("Saved %s (%d zones)" % [_output_path, _zone_count])
	return true

var _zone_count := 0

func _collect_zones(node: Node, out: Array) -> void:
	if node is Zone:
		var z := node as Zone
		if z.area:
			var has_scatter := false
			for c in z.get_children():
				if c is DecorationScatter:
					has_scatter = true
					break
			out.append({
				"name": z.name,
				"area": z.area,
				"kind": z.kind,
				"origin": z.global_position,
				"decorated": has_scatter,
				"bare": z.deliberately_bare,
			})
			_zone_count += 1
	for child in node.get_children():
		_collect_zones(child, out)


class _ZoneOverlay:
	extends Node2D
	var zones: Array
	const KIND_NAMES := ["OPEN", "ENCLOSED", "SOLID"]
	# OPEN green, ENCLOSED orange, SOLID red.
	const KIND_COLORS := [
		Color(0.3, 1.0, 0.4, 1.0),
		Color(1.0, 0.65, 0.2, 1.0),
		Color(1.0, 0.3, 0.3, 1.0),
	]

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		for z in zones:
			var area = z["area"]
			var kind: int = z["kind"]
			var origin: Vector2 = z["origin"]
			var color: Color = KIND_COLORS[kind]
			var status := ""
			if z["bare"]:
				status = " (bare)"
			elif not z["decorated"] and kind != 2:
				status = " !UNDECORATED"
			var label := "%s [%s]%s" % [z["name"], KIND_NAMES[kind], status]
			var r = area.get("rect")
			if r is Rect2:
				var screen := Rect2(r.position + origin, r.size)
				draw_rect(screen, color, false, 2.0)
				var pos := screen.position + Vector2(4, 14)
				for ox in [-1, 1]:
					for oy in [-1, 1]:
						draw_string(font, pos + Vector2(ox, oy), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0, 0, 0, 1))
				draw_string(font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)
