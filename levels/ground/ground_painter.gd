@tool
extends Node2D

class_name GroundPainter

# Paints a stage's ground TileMap at load: fills the whole map with a base
# terrain, then paints each TerrainRegion on top (paths, patches).
#
# Like DecorationScatter, this regenerates at _ready (in the editor too), so
# the TileMap is left empty in the saved scene — the GroundPainter config is
# the single source of truth. base_level ships an empty TileMap; each stage
# carries one GroundPainter pointing at it.
#
# Terrain painting uses Godot's autotiling (set_cells_terrain_connect), so
# edges/corners between terrains are picked automatically. Paths want to be
# >= 3 cells wide (the grass/dirt set is an 18-tile minimal autotile with no
# tile for a 1-2 wide strip).

const GROUND_LAYER := 0
const TERRAIN_SET := 0

@export var tile_map: TileMap: set = _set_tile_map
## Map size in cells (960x540 stage / 16px = 60x34).
@export var map_size: Vector2i = Vector2i(60, 34): set = _set_map_size
## Terrain index used to fill the whole map (0 = Grass).
@export var base_terrain: int = 0: set = _set_base_terrain
## Extra terrain regions painted on top of the base fill, in array order.
@export var regions: Array[TerrainRegion] = []: set = _set_regions
@export_tool_button("Repaint") var _repaint_button = paint

func _ready() -> void:
	paint()

func paint() -> void:
	if not tile_map:
		return
	if not tile_map.tile_set:
		push_warning("GroundPainter: tile_map has no TileSet assigned")
		return
	tile_map.clear_layer(GROUND_LAYER)

	var base_cells: Array[Vector2i] = []
	for x in map_size.x:
		for y in map_size.y:
			base_cells.append(Vector2i(x, y))
	tile_map.set_cells_terrain_connect(GROUND_LAYER, base_cells, TERRAIN_SET, base_terrain)

	for region in regions:
		if not region:
			continue
		var cells: Array[Vector2i] = []
		for x in range(region.rect.position.x, region.rect.position.x + region.rect.size.x):
			for y in range(region.rect.position.y, region.rect.position.y + region.rect.size.y):
				cells.append(Vector2i(x, y))
		if not cells.is_empty():
			tile_map.set_cells_terrain_connect(GROUND_LAYER, cells, TERRAIN_SET, region.terrain)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not tile_map:
		warnings.append("tile_map is not set — assign the stage's TileMap.")
	return warnings

func _set_tile_map(v: TileMap) -> void:
	tile_map = v
	_on_changed()

func _set_map_size(v: Vector2i) -> void:
	map_size = v
	_on_changed()

func _set_base_terrain(v: int) -> void:
	base_terrain = v
	_on_changed()

func _set_regions(v: Array[TerrainRegion]) -> void:
	regions = v
	_on_changed()

func _on_changed() -> void:
	update_configuration_warnings()
	if is_inside_tree():
		paint()
