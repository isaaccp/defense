extends SceneTree

# Renders all decoration .tscn files in a directory into a single grid PNG
# with a label under each, so a human can verify each prop is showing the
# correct atlas region without staring at micro-pixels in a level render.
#
# Usage:
#   godot --path . -s tools/render_decoration_grid.gd -- <decoration_dir> <output_png>
#   xvfb-run -a godot --path . -s tools/render_decoration_grid.gd -- ...
#
# Each cell is large enough that a 32x32 atlas region is clearly readable;
# scenes that anchor with offset (e.g. tree.offset = Vector2(0, -45)) are
# positioned so the anchor lands at the bottom-center of the cell, mirroring
# how decorations sit in-world.

const CELL_SIZE := Vector2i(160, 160)
const COLS := 5
const PADDING := 12
const LABEL_HEIGHT := 28
const WARMUP_FRAMES := 10

var _viewport: SubViewport
var _output_path: String
var _frames := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("Usage: godot --path . -s tools/render_decoration_grid.gd -- <decoration_dir> <output_png>")
		quit(1)
		return
	var decoration_dir: String = args[0]
	_output_path = args[1]
	if not decoration_dir.begins_with("res://"):
		decoration_dir = "res://" + decoration_dir
	decoration_dir = decoration_dir.trim_suffix("/")

	var scene_paths := _find_tscn_files(decoration_dir)
	if scene_paths.is_empty():
		push_error("No .tscn files found under %s" % decoration_dir)
		quit(1)
		return

	var rows: int = ceili(float(scene_paths.size()) / float(COLS))
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

	# Solid neutral grey background so transparent props (no collision body
	# fill) are visible — uses a CanvasLayer + ColorRect.
	var bg := ColorRect.new()
	bg.color = Color(0.35, 0.45, 0.35)  # muted forest green to match in-game
	bg.size = canvas_size
	_viewport.add_child(bg)

	for i in scene_paths.size():
		var row: int = i / COLS
		var col: int = i % COLS
		var cell_origin := Vector2(
			PADDING + col * (CELL_SIZE.x + PADDING),
			PADDING + row * (CELL_SIZE.y + LABEL_HEIGHT + PADDING)
		)
		# Anchor at bottom-center of the cell rect (matches in-world placement,
		# where decorations have their base at position.y).
		var anchor := cell_origin + Vector2(float(CELL_SIZE.x) / 2.0, float(CELL_SIZE.y) - 8.0)

		var packed := load(scene_paths[i]) as PackedScene
		if not packed:
			push_error("Could not load %s" % scene_paths[i])
			continue
		var inst := packed.instantiate()
		if inst is Node2D:
			(inst as Node2D).position = anchor
		_viewport.add_child(inst)

		# Faint cell border to make grid structure obvious.
		var border := ReferenceRect.new()
		border.position = cell_origin
		border.size = Vector2(CELL_SIZE)
		border.border_color = Color(1, 1, 1, 0.25)
		border.border_width = 1.0
		border.editor_only = false
		_viewport.add_child(border)

		var label := Label.new()
		label.text = scene_paths[i].get_file().get_basename()
		label.position = cell_origin + Vector2(0, CELL_SIZE.y + 2)
		label.size = Vector2(CELL_SIZE.x, LABEL_HEIGHT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		label.add_theme_constant_override("outline_size", 4)
		_viewport.add_child(label)

func _find_tscn_files(dir_path: String) -> Array[String]:
	var result: Array[String] = []
	var d := DirAccess.open(dir_path)
	if d == null:
		push_error("Could not open dir: %s" % dir_path)
		return result
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		if not name.begins_with(".") and name.ends_with(".tscn"):
			result.append("%s/%s" % [dir_path, name])
		name = d.get_next()
	result.sort()
	return result

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < WARMUP_FRAMES:
		return false
	var image := _viewport.get_texture().get_image()
	if not image or image.is_empty():
		push_error("Empty image — rendering driver may be null. Try xvfb-run.")
		return true
	var err := image.save_png(_output_path)
	if err != OK:
		push_error("save_png failed: %s" % err)
		return true
	print("Saved %s (%dx%d)" % [_output_path, image.get_width(), image.get_height()])
	return true
