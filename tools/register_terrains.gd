extends SceneTree

# Registers terrain autotiles into a TileSet, driven by a blocks JSON
# (green_woods_tiles_blocks.json). For each block with a "register" entry:
#   - "autotile3x3": creates the 9 tiles of a 3x3 minimal autotile and tags
#     each with terrain_set/terrain + the 8 peering bits per the standard
#     "match corners and sides" pattern.
#   - "plain": creates the tiles and tags them as fully-surrounded by one
#     terrain (interchangeable centre tiles -> fill variety).
# Blocks with "already_registered": true are skipped (e.g. the Grass/Dirt
# pair already in tiles.tres).
#
# Idempotent: existing tiles are reused, terrain data re-applied.
#
# Usage: godot --headless --path . -s tools/register_terrains.gd -- <blocks_json>

const PEERING := {
	"left":         TileSet.CELL_NEIGHBOR_LEFT_SIDE,
	"right":        TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
	"top":          TileSet.CELL_NEIGHBOR_TOP_SIDE,
	"bottom":       TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	"top_left":     TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
	"top_right":    TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
	"bottom_left":  TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	"bottom_right": TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
}

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("Usage: godot --headless --path . -s tools/register_terrains.gd -- <blocks_json>")
		quit(1)
		return
	var config_path: String = args[0]
	if not config_path.begins_with("res://"):
		config_path = "res://" + config_path

	var f := FileAccess.open(config_path, FileAccess.READ)
	if not f:
		push_error("Could not open config: %s" % config_path)
		quit(1)
		return
	var cfg = JSON.parse_string(f.get_as_text())
	if cfg == null:
		push_error("Bad JSON")
		quit(1)
		return

	var tileset_path: String = cfg["tileset"]
	var tileset := load(tileset_path) as TileSet
	if not tileset:
		push_error("Could not load TileSet: %s" % tileset_path)
		quit(1)
		return

	# Ensure terrain_set 0 has all declared terrains, named + colored.
	var terrains: Array = cfg["terrains"]
	while tileset.get_terrains_count(0) < terrains.size():
		tileset.add_terrain(0)
	for t in terrains:
		var tid: int = int(t["id"])
		tileset.set_terrain_name(0, tid, t["name"])
		var c: Array = t["color"]
		tileset.set_terrain_color(0, tid, Color(c[0], c[1], c[2], c[3]))
		print("  terrain %d = %s" % [tid, t["name"]])

	# Find the Tiles.png atlas source.
	var src: TileSetAtlasSource = null
	for i in tileset.get_source_count():
		var sid := tileset.get_source_id(i)
		var s := tileset.get_source(sid)
		if s is TileSetAtlasSource:
			var atlas := s as TileSetAtlasSource
			if atlas.texture and atlas.texture.resource_path.ends_with("Tiles.png"):
				src = atlas
				break
	if not src:
		push_error("Could not find Tiles.png atlas source in TileSet")
		quit(1)
		return

	var registered := 0
	for b in cfg["blocks"]:
		var block: Dictionary = b
		if not block.has("register"):
			continue
		var reg: Dictionary = block["register"]
		if reg.get("already_registered", false):
			continue
		var cells: Array = block["cells"]
		var oc := int(cells[0])
		var orow := int(cells[1])
		var w := int(cells[2])
		var h := int(cells[3])
		match reg["type"]:
			"autotile3x3":
				_register_3x3(src, oc, orow, int(reg["inside"]), int(reg["outside"]))
				print("  registered autotile3x3: %s" % block["name"])
				registered += 1
			"plain":
				_register_plain(src, oc, orow, w, h, int(reg["terrain"]), float(reg.get("probability", 1.0)))
				print("  registered plain x%d: %s" % [w * h, block["name"]])
				registered += 1

	var err := ResourceSaver.save(tileset, tileset_path)
	if err != OK:
		push_error("save failed: %s" % err)
		quit(1)
		return
	print("Registered %d blocks; saved %s" % [registered, tileset_path])
	quit(0)

func _ensure_tile(src: TileSetAtlasSource, coords: Vector2i) -> TileData:
	if not src.has_tile(coords):
		src.create_tile(coords)
	return src.get_tile_data(coords, 0)

func _register_3x3(src: TileSetAtlasSource, oc: int, orow: int, inside: int, outside: int) -> void:
	for dc in 3:
		for dr in 3:
			var td := _ensure_tile(src, Vector2i(oc + dc, orow + dr))
			td.terrain_set = 0
			td.terrain = inside
			var bits := {
				"left":         inside if dc > 0 else outside,
				"right":        inside if dc < 2 else outside,
				"top":          inside if dr > 0 else outside,
				"bottom":       inside if dr < 2 else outside,
				"top_left":     inside if (dc > 0 and dr > 0) else outside,
				"top_right":    inside if (dc < 2 and dr > 0) else outside,
				"bottom_left":  inside if (dc > 0 and dr < 2) else outside,
				"bottom_right": inside if (dc < 2 and dr < 2) else outside,
			}
			for k in bits:
				td.set_terrain_peering_bit(PEERING[k], bits[k])

func _register_plain(src: TileSetAtlasSource, oc: int, orow: int, w: int, h: int, terrain: int, probability: float) -> void:
	for dc in w:
		for dr in h:
			var td := _ensure_tile(src, Vector2i(oc + dc, orow + dr))
			td.terrain_set = 0
			td.terrain = terrain
			for k in PEERING:
				td.set_terrain_peering_bit(PEERING[k], terrain)
			if probability != 1.0:
				td.probability = probability
