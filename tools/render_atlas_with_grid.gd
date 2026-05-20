extends SceneTree

# Renders a sprite atlas at high zoom with a 16x16 pixel grid + axis labels,
# so we can identify regions by coordinate without eyeballing micro-pixels.
#
# Usage:
#   godot --path . -s tools/render_atlas_with_grid.gd -- <atlas_png> <output_png> [zoom]
#   xvfb-run -a godot --path . -s tools/render_atlas_with_grid.gd -- ...
#
# Default zoom = 4x. At 16x16 cell size, zoom=4 makes each cell 64x64 in the
# output — readable and labelable.

const GRID := 16
const WARMUP_FRAMES := 10
const LABEL_MARGIN := 36  # space on top + left for axis labels

var _viewport: SubViewport
var _output_path: String
var _frames := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("Usage: godot --path . -s tools/render_atlas_with_grid.gd -- <atlas_png> <output_png> [zoom]")
		quit(1)
		return
	var atlas_path: String = args[0]
	_output_path = args[1]
	var zoom: int = int(args[2]) if args.size() >= 3 else 4

	if not atlas_path.begins_with("res://"):
		atlas_path = "res://" + atlas_path

	var tex: Texture2D = load(atlas_path) as Texture2D
	if not tex:
		push_error("Could not load atlas: %s" % atlas_path)
		quit(1)
		return

	var tex_size := tex.get_size()
	var canvas_size := Vector2i(
		int(tex_size.x * zoom) + LABEL_MARGIN,
		int(tex_size.y * zoom) + LABEL_MARGIN
	)

	_viewport = SubViewport.new()
	_viewport.size = canvas_size
	_viewport.disable_3d = true
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.12, 0.14)
	bg.size = canvas_size
	_viewport.add_child(bg)

	# Atlas image at LABEL_MARGIN offset, zoomed
	var sprite := TextureRect.new()
	sprite.texture = tex
	sprite.position = Vector2(LABEL_MARGIN, LABEL_MARGIN)
	sprite.size = tex_size * zoom
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # crisp pixels
	_viewport.add_child(sprite)

	# Grid overlay + labels via a custom drawing node
	var grid := _GridDrawer.new()
	grid.tex_size = tex_size
	grid.zoom = zoom
	grid.label_margin = LABEL_MARGIN
	grid.grid = GRID
	_viewport.add_child(grid)

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


class _GridDrawer:
	extends Node2D
	var tex_size: Vector2
	var zoom: int
	var label_margin: int
	var grid: int

	func _draw() -> void:
		var origin := Vector2(label_margin, label_margin)
		var line_color := Color(1, 1, 0, 0.4)
		var thick_color := Color(1, 1, 1, 0.6)
		var label_color := Color(1, 1, 1, 1)
		var label_outline := Color(0, 0, 0, 1)

		# Vertical lines + x-axis labels
		var x: int = 0
		while x <= int(tex_size.x):
			var px := origin.x + x * zoom
			var c := thick_color if x % (grid * 4) == 0 else line_color
			draw_line(Vector2(px, origin.y), Vector2(px, origin.y + tex_size.y * zoom), c, 1.0)
			if x % grid == 0:
				_draw_label(str(x), Vector2(px - 8, origin.y - 16), label_color, label_outline)
			x += grid

		# Horizontal lines + y-axis labels
		var y: int = 0
		while y <= int(tex_size.y):
			var py := origin.y + y * zoom
			var c2 := thick_color if y % (grid * 4) == 0 else line_color
			draw_line(Vector2(origin.x, py), Vector2(origin.x + tex_size.x * zoom, py), c2, 1.0)
			if y % grid == 0:
				_draw_label(str(y), Vector2(2, py - 6), label_color, label_outline)
			y += grid

	func _draw_label(text: String, at: Vector2, color: Color, outline: Color) -> void:
		var font := ThemeDB.fallback_font
		var size := 12
		# Outline (4-direction offset for legibility on busy atlases)
		for ox in [-1, 1]:
			for oy in [-1, 1]:
				draw_string(font, at + Vector2(ox, oy), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline)
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
