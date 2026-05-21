@tool
extends Resource

class_name TerrainRegion

# A rectangular region (in TileMap cell coordinates) painted with one terrain.
# Used by GroundPainter to lay paths / patches on top of the base fill.

## Terrain index within terrain set 0 (0 = Grass, 1 = Dirt, 2 = Teal Grass).
@export var terrain: int = 1
## Region in TileMap cells (position + size).
@export var rect: Rect2i = Rect2i(0, 0, 1, 1)
