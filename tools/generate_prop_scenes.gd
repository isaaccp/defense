extends SceneTree

# Generates a prop_<name>.tscn for every entry in a props JSON config.
# Passable props -> a bare Sprite2D. Obstacle props -> StaticBody2D with a
# Sprite2D and a CollisionShape2D (small circle footprint at the base).
#
# The sprite is offset up by half its height so the prop's base sits at the
# node origin — matches how DecorationScatter places things (position = ground
# point).
#
# Usage:
#   godot --path . -s tools/generate_prop_scenes.gd -- <config_json> <output_dir>

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("Usage: godot --path . -s tools/generate_prop_scenes.gd -- <config_json> <output_dir>")
		quit(1)
		return
	var config_path: String = args[0]
	var output_dir: String = args[1]
	if not config_path.begins_with("res://"):
		config_path = "res://" + config_path
	if not output_dir.begins_with("res://"):
		output_dir = "res://" + output_dir
	output_dir = output_dir.trim_suffix("/")

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
	var atlas: Texture2D = load(atlas_path) as Texture2D
	if not atlas:
		push_error("Could not load atlas: %s" % atlas_path)
		quit(1)
		return

	var props: Array = cfg["props"]
	var generated := 0
	for p in props:
		var prop: Dictionary = p
		var prop_name: String = prop["name"]
		var rect_arr: Array = prop["rect"]
		var rect := Rect2(rect_arr[0], rect_arr[1], rect_arr[2], rect_arr[3])
		var obstacle: bool = prop.get("obstacle", false)
		# Flat props (flower patches, ground decals) lie ON the ground. Their
		# y-sort origin is the patch's TOP edge, so the patch extends only
		# downward — it can only draw over a tree once the whole patch is past
		# (below) that tree's base, never poking up over its trunk.
		# Upright props (trees, crates, mushrooms) anchor at their base.
		var flat: bool = prop.get("flat", false)

		var atlas_tex := AtlasTexture.new()
		atlas_tex.atlas = atlas
		atlas_tex.region = rect

		var sprite_offset := Vector2(0, rect.size.y / 2.0) if flat else Vector2(0, -rect.size.y / 2.0)

		var root: Node2D
		if obstacle:
			root = StaticBody2D.new()
			root.name = _pascal(prop_name)

			var sprite := Sprite2D.new()
			sprite.name = "Sprite2D"
			sprite.texture = atlas_tex
			sprite.offset = sprite_offset
			root.add_child(sprite)
			sprite.owner = root

			var collision := CollisionShape2D.new()
			collision.name = "CollisionShape2D"
			var shape := CircleShape2D.new()
			# Footprint radius: ~40% of the narrower dimension, min 5.
			shape.radius = maxf(5.0, minf(rect.size.x, rect.size.y) * 0.4)
			collision.shape = shape
			root.add_child(collision)
			collision.owner = root
		else:
			root = Sprite2D.new()
			root.name = _pascal(prop_name)
			(root as Sprite2D).texture = atlas_tex
			(root as Sprite2D).offset = sprite_offset

		var packed := PackedScene.new()
		var err := packed.pack(root)
		if err != OK:
			push_error("pack failed for %s: %s" % [prop_name, err])
			continue
		var out_path := "%s/prop_%s.tscn" % [output_dir, prop_name]
		err = ResourceSaver.save(packed, out_path)
		if err != OK:
			push_error("save failed for %s: %s" % [prop_name, err])
			continue
		generated += 1
		print("  prop_%s.tscn  (%s)" % [prop_name, "obstacle" if obstacle else "passable"])

	print("Generated %d prop scenes in %s" % [generated, output_dir])
	quit(0)

func _pascal(snake: String) -> String:
	var parts := snake.split("_")
	var result := ""
	for part in parts:
		if part.length() > 0:
			result += part.substr(0, 1).to_upper() + part.substr(1)
	return result
