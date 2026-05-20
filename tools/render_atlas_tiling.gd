extends SceneTree

# Phase A of the prop-extraction workflow.
# Reads a JSON config { atlas, props: [{ name, rect: [x,y,w,h] }, ...] } and
# renders the atlas at high zoom with all proposed rects overlaid as labeled
# colored boxes. Lets a human verify the *tiling decision* (are these the
# right boundaries on the spritesheet?) before committing to extracting them.
#
# Usage:
#   godot --path . -s tools/render_atlas_tiling.gd -- <config_json> <output_png> [zoom]
#   xvfb-run -a godot --path . -s tools/render_atlas_tiling.gd -- ...

const WARMUP_FRAMES := 10
const GRID := 16

var _viewport: SubViewport
var _output_path: String
var _frames := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("Usage: godot --path . -s tools/render_atlas_tiling.gd -- <config_json> <output_png> [zoom]")
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
	var props: Array = cfg["props"]

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
	bg.color = Color(0.10, 0.10, 0.12)
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

	var grid := _GridOverlay.new()
	grid.tex_size = tex_size
	grid.zoom = zoom
	_viewport.add_child(grid)

	var overlay := _RectsOverlay.new()
	overlay.zoom = zoom
	overlay.props = props
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


class _GridOverlay:
	extends Node2D
	var tex_size: Vector2
	var zoom: int
	func _draw() -> void:
		# Thin lines every 16px, thicker every 64px.
		var thin := Color(1, 1, 1, 0.10)
		var thick := Color(1, 1, 1, 0.25)
		var x := 0
		while x <= int(tex_size.x):
			var c := thick if x % 64 == 0 else thin
			draw_line(Vector2(x * zoom, 0), Vector2(x * zoom, tex_size.y * zoom), c, 1.0)
			x += 16
		var y := 0
		while y <= int(tex_size.y):
			var c2 := thick if y % 64 == 0 else thin
			draw_line(Vector2(0, y * zoom), Vector2(tex_size.x * zoom, y * zoom), c2, 1.0)
			y += 16


class _RectsOverlay:
	extends Node2D
	var zoom: int
	var props: Array
	# Distinct colors so adjacent rects are easy to tell apart.
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
		var font := ThemeDB.fallback_font
		for i in props.size():
			var p: Dictionary = props[i]
			var rect: Array = p["rect"]
			var name: String = p["name"]
			var color: Color = PALETTE[i % PALETTE.size()]
			var screen_rect := Rect2(
				rect[0] * zoom, rect[1] * zoom,
				rect[2] * zoom, rect[3] * zoom
			)
			draw_rect(screen_rect, color, false, 3.0)
			# Filled label background
			var label_pos := Vector2(screen_rect.position.x + 3, screen_rect.position.y + 14)
			var size_str := "%dx%d" % [int(rect[2] / 16), int(rect[3] / 16)]
			var text := "%s [%s]" % [name, size_str]
			# outline
			for ox in [-1, 1]:
				for oy in [-1, 1]:
					draw_string(font, label_pos + Vector2(ox, oy), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0, 0, 0, 1))
			draw_string(font, label_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
