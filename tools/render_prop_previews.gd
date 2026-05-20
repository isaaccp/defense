extends SceneTree

# Phase B of the prop-extraction workflow.
# Reads the same JSON config as render_atlas_tiling.gd and renders each prop's
# region as a clean, isolated, zoomed cell in a labeled grid. Lets a human
# verify each *extracted* prop looks correct (no clipping, no bleed) before any
# scene files are created.
#
# Usage:
#   godot --path . -s tools/render_prop_previews.gd -- <config_json> <output_png> [zoom]
#   xvfb-run -a godot --path . -s tools/render_prop_previews.gd -- ...

const CELL_SIZE := Vector2i(160, 160)
const COLS := 6
const PADDING := 12
const LABEL_HEIGHT := 30
const WARMUP_FRAMES := 10

var _viewport: SubViewport
var _output_path: String
var _frames := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("Usage: godot --path . -s tools/render_prop_previews.gd -- <config_json> <output_png> [zoom]")
		quit(1)
		return
	var config_path: String = args[0]
	_output_path = args[1]
	var zoom: int = int(args[2]) if args.size() >= 3 else 3

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

	var rows: int = ceili(float(props.size()) / float(COLS))
	var canvas_size := Vector2i(
		PADDING + COLS * (CELL_SIZE.x + PADDING),
		PADDING + rows * (CELL_SIZE.y + LABEL_HEIGHT + PADDING)
	)

	_viewport = SubViewport.new()
	_viewport.size = canvas_size
	_viewport.disable_3d = true
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)

	var bg := ColorRect.new()
	bg.color = Color(0.35, 0.45, 0.35)  # muted forest green, matches in-game grass
	bg.size = canvas_size
	_viewport.add_child(bg)

	for i in props.size():
		var p: Dictionary = props[i]
		var rect: Array = p["rect"]
		var prop_name: String = p["name"]
		var obstacle: bool = p.get("obstacle", false)

		var row: int = i / COLS
		var col: int = i % COLS
		var cell_origin := Vector2(
			PADDING + col * (CELL_SIZE.x + PADDING),
			PADDING + row * (CELL_SIZE.y + LABEL_HEIGHT + PADDING)
		)

		var atlas_tex := AtlasTexture.new()
		atlas_tex.atlas = tex
		atlas_tex.region = Rect2(rect[0], rect[1], rect[2], rect[3])

		var sprite := Sprite2D.new()
		sprite.texture = atlas_tex
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(zoom, zoom)
		# Center the prop in the cell.
		sprite.position = cell_origin + Vector2(CELL_SIZE) / 2.0
		_viewport.add_child(sprite)

		var border := ReferenceRect.new()
		border.position = cell_origin
		border.size = Vector2(CELL_SIZE)
		border.border_color = Color(1, 1, 1, 0.25)
		border.border_width = 1.0
		border.editor_only = false
		_viewport.add_child(border)

		var size_tiles := "%dx%d" % [int(rect[2]) / 16, int(rect[3]) / 16]
		var obstacle_mark := "  [obstacle]" if obstacle else ""
		var label := Label.new()
		label.text = "%s\n%s%s" % [prop_name, size_tiles, obstacle_mark]
		label.position = cell_origin + Vector2(0, CELL_SIZE.y + 2)
		label.size = Vector2(CELL_SIZE.x, LABEL_HEIGHT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		label.add_theme_constant_override("outline_size", 4)
		label.add_theme_font_size_override("font_size", 13)
		_viewport.add_child(label)

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
