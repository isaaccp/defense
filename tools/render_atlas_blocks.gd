extends SceneTree

# Renders an atlas at high zoom with: a 16px cell grid, cell row/col INDICES
# labelled along the top and left edges, and a set of proposed "blocks"
# (regions given in CELL coordinates) drawn as labelled colored rects.
#
# Used to agree on how a terrain spritesheet is divided into terrain blocks,
# the way render_atlas_tiling.gd is used for prop rects.
#
# Config JSON: { atlas, cols, rows, blocks: [{ name, cells: [col,row,w,h] }] }
#
# Usage:
#   godot --path . -s tools/render_atlas_blocks.gd -- <config_json> <output_png> [zoom]
#   xvfb-run -a godot --path . -s tools/render_atlas_blocks.gd -- ...

const CELL := 16
const MARGIN := 64
const WARMUP_FRAMES := 10

var _viewport: SubViewport
var _output_path: String
var _frames := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("Usage: godot --path . -s tools/render_atlas_blocks.gd -- <config_json> <output_png> [zoom]")
		quit(1)
		return
	var config_path: String = args[0]
	_output_path = args[1]
	var zoom: int = int(args[2]) if args.size() >= 3 else 6
	if not config_path.begins_with("res://"):
		config_path = "res://" + config_path

	var f := FileAccess.open(config_path, FileAccess.READ)
	if not f:
		push_error("Could not open config: %s" % config_path)
		quit(1)
		return
	var cfg = JSON.parse_string(f.get_as_text())
	if cfg == null:
		push_error("Bad JSON: %s" % config_path)
		quit(1)
		return

	var atlas_path: String = cfg["atlas"]
	var blocks: Array = cfg["blocks"]
	# Optional crop window into the atlas, in cells: [col_start, row_start, cols, rows].
	# Defaults to [0, 0, cfg.cols, cfg.rows].
	var col_start := 0
	var row_start := 0
	var cols: int = int(cfg["cols"])
	var rows: int = int(cfg["rows"])
	if cfg.has("view"):
		var v: Array = cfg["view"]
		col_start = int(v[0])
		row_start = int(v[1])
		cols = int(v[2])
		rows = int(v[3])

	var tex: Texture2D = load(atlas_path) as Texture2D
	if not tex:
		push_error("Could not load atlas: %s" % atlas_path)
		quit(1)
		return

	var content_w := cols * CELL * zoom
	var content_h := rows * CELL * zoom
	var canvas_size := Vector2i(MARGIN + content_w, MARGIN + content_h)

	_viewport = SubViewport.new()
	_viewport.size = canvas_size
	_viewport.disable_3d = true
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)

	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.10, 0.12)
	bg.size = canvas_size
	_viewport.add_child(bg)

	# Atlas drawn so the crop window's top-left lands at (MARGIN, MARGIN).
	var sprite := TextureRect.new()
	sprite.texture = tex
	sprite.position = Vector2(
		MARGIN - col_start * CELL * zoom,
		MARGIN - row_start * CELL * zoom
	)
	sprite.size = tex.get_size() * zoom
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_viewport.add_child(sprite)

	var overlay := _Overlay.new()
	overlay.cols = cols
	overlay.rows = rows
	overlay.col_start = col_start
	overlay.row_start = row_start
	overlay.zoom = zoom
	overlay.blocks = blocks
	_viewport.add_child(overlay)

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


class _Overlay:
	extends Node2D
	var cols: int
	var rows: int
	var col_start: int
	var row_start: int
	var zoom: int
	var blocks: Array
	const CELL := 16
	const MARGIN := 64
	const PALETTE := [
		Color(1.00, 0.30, 0.30, 1.0),
		Color(0.30, 0.70, 1.00, 1.0),
		Color(0.30, 1.00, 0.50, 1.0),
		Color(1.00, 0.85, 0.20, 1.0),
		Color(1.00, 0.50, 0.95, 1.0),
		Color(0.55, 1.00, 1.00, 1.0),
		Color(1.00, 0.65, 0.20, 1.0),
		Color(0.60, 0.50, 1.00, 1.0),
	]

	func _draw() -> void:
		var step := CELL * zoom
		var font := ThemeDB.fallback_font
		var grid_col := Color(1, 1, 1, 0.18)

		# Grid lines.
		for c in range(cols + 1):
			var x := MARGIN + c * step
			draw_line(Vector2(x, MARGIN), Vector2(x, MARGIN + rows * step), grid_col, 1.0)
		for r in range(rows + 1):
			var y := MARGIN + r * step
			draw_line(Vector2(MARGIN, y), Vector2(MARGIN + cols * step, y), grid_col, 1.0)

		# Column indices along the top (absolute atlas cell indices).
		for c in range(cols):
			var cx := MARGIN + c * step + step / 2.0
			_centered_text(font, str(col_start + c), Vector2(cx, MARGIN / 2.0), 22, Color(1, 1, 1, 0.9))
		# Row indices down the left.
		for r in range(rows):
			var cy := MARGIN + r * step + step / 2.0
			_centered_text(font, str(row_start + r), Vector2(MARGIN / 2.0, cy), 22, Color(1, 1, 1, 0.9))

		# Blocks (cells are absolute atlas coords; offset by the crop window).
		for i in blocks.size():
			var b: Dictionary = blocks[i]
			var cells: Array = b["cells"]
			var color: Color = PALETTE[i % PALETTE.size()]
			var rect := Rect2(
				MARGIN + (cells[0] - col_start) * step,
				MARGIN + (cells[1] - row_start) * step,
				cells[2] * step,
				cells[3] * step
			)
			draw_rect(rect, color, false, 4.0)
			var label := "%s  [c%d r%d  %dx%d]" % [b["name"], cells[0], cells[1], cells[2], cells[3]]
			var pos := rect.position + Vector2(5, 18)
			for ox in [-1, 1]:
				for oy in [-1, 1]:
					draw_string(font, pos + Vector2(ox, oy), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0, 0, 0, 1))
			draw_string(font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)

	func _centered_text(font: Font, text: String, center: Vector2, size: int, color: Color) -> void:
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var pos := center - Vector2(w / 2.0, -size / 3.0)
		for ox in [-1, 1]:
			for oy in [-1, 1]:
				draw_string(font, pos + Vector2(ox, oy), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 1))
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
