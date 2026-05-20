extends SceneTree

# Renders an atlas PNG at high zoom with a red rectangle drawn over a candidate
# region. Useful for verifying region bounds before committing — visually
# answers "is this rect the thing I want, or is it cropping/bleeding?"
#
# Usage:
#   godot --path . -s tools/render_atlas_region.gd -- <atlas_png> <output_png> <x> <y> <w> <h> [zoom]
#   xvfb-run -a godot --path . -s tools/render_atlas_region.gd -- ...

const WARMUP_FRAMES := 10

var _viewport: SubViewport
var _output_path: String
var _frames := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 6:
		print("Usage: godot --path . -s tools/render_atlas_region.gd -- <atlas_png> <output_png> <x> <y> <w> <h> [zoom]")
		quit(1)
		return
	var atlas_path: String = args[0]
	_output_path = args[1]
	var rx := int(args[2])
	var ry := int(args[3])
	var rw := int(args[4])
	var rh := int(args[5])
	var zoom: int = int(args[6]) if args.size() >= 7 else 6

	if not atlas_path.begins_with("res://"):
		atlas_path = "res://" + atlas_path

	var tex: Texture2D = load(atlas_path) as Texture2D
	if not tex:
		push_error("Could not load atlas: %s" % atlas_path)
		quit(1)
		return

	var tex_size := tex.get_size()
	var canvas_size := Vector2i(int(tex_size.x * zoom), int(tex_size.y * zoom))

	_viewport = SubViewport.new()
	_viewport.size = canvas_size
	_viewport.disable_3d = true
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)

	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.12, 0.14)
	bg.size = canvas_size
	_viewport.add_child(bg)

	var sprite := TextureRect.new()
	sprite.texture = tex
	sprite.position = Vector2.ZERO
	sprite.size = tex_size * zoom
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_viewport.add_child(sprite)

	# 16-px grid overlay for context
	var grid := _GridOverlay.new()
	grid.tex_size = tex_size
	grid.zoom = zoom
	_viewport.add_child(grid)

	# Region highlight
	var hl := _RegionHighlight.new()
	hl.region = Rect2(rx * zoom, ry * zoom, rw * zoom, rh * zoom)
	hl.label = "(%d, %d, %d, %d)" % [rx, ry, rw, rh]
	_viewport.add_child(hl)

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < WARMUP_FRAMES:
		return false
	var image := _viewport.get_texture().get_image()
	if not image or image.is_empty():
		push_error("Empty image — try xvfb-run.")
		return true
	var err := image.save_png(_output_path)
	if err != OK:
		push_error("save_png failed: %s" % err)
		return true
	print("Saved %s (%dx%d)" % [_output_path, image.get_width(), image.get_height()])
	return true


class _GridOverlay:
	extends Node2D
	var tex_size: Vector2
	var zoom: int
	func _draw() -> void:
		var line := Color(1, 1, 1, 0.15)
		var x := 0
		while x <= int(tex_size.x):
			draw_line(Vector2(x * zoom, 0), Vector2(x * zoom, tex_size.y * zoom), line, 1.0)
			x += 16
		var y := 0
		while y <= int(tex_size.y):
			draw_line(Vector2(0, y * zoom), Vector2(tex_size.x * zoom, y * zoom), line, 1.0)
			y += 16


class _RegionHighlight:
	extends Node2D
	var region: Rect2
	var label: String
	func _draw() -> void:
		draw_rect(region, Color(1, 0.2, 0.2, 1), false, 3.0)
		var font := ThemeDB.fallback_font
		var pos := region.position + Vector2(4, -4)
		for ox in [-1, 1]:
			for oy in [-1, 1]:
				draw_string(font, pos + Vector2(ox, oy), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0, 0, 0, 1))
		draw_string(font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.4, 0.4, 1))
