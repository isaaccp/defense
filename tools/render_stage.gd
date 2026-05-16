extends SceneTree

# Renders a level/stage scene to a PNG so we can visually verify spatial
# design without running the game. Usage:
#   godot --path . -s tools/render_stage.gd -- <scene_path> <output_png>
#
# Note: this needs a real rendering driver — `--headless` alone uses a null
# renderer and produces an empty image. If you have no display attached, use
#   xvfb-run -a godot --path . -s tools/render_stage.gd -- ...

const CANVAS_SIZE := Vector2i(960, 540)
const WARMUP_FRAMES := 10

var _viewport: SubViewport
var _output_path: String
var _frames := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("Usage: godot --path . -s tools/render_stage.gd -- <scene_path> <output_png>")
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
	_viewport.size = CANVAS_SIZE
	_viewport.disable_3d = true
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)

	# Child of SubViewport (not root) so Level._ready doesn't trigger its
	# standalone-F6 setup path. Level enters PREPARE during warmup, which
	# makes PlacementZones visible — they show as a subtle tint over grass.
	var scene := packed.instantiate()
	_viewport.add_child(scene)

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < WARMUP_FRAMES:
		return false
	var image := _viewport.get_texture().get_image()
	if not image or image.is_empty():
		push_error("Empty image — rendering driver may be null. Try without --headless or use xvfb-run.")
		return true
	var err := image.save_png(_output_path)
	if err != OK:
		push_error("save_png failed: %s" % err)
		return true
	print("Saved %s (%dx%d)" % [_output_path, image.get_width(), image.get_height()])
	return true
