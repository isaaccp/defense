# Spritesheet Ingestion Workflow

How to turn a raw art spritesheet into usable game assets (prop scenes, or
registered TileSet terrains). Follow this whenever a new spritesheet needs to
be brought into the game.

## Why this workflow exists

Spritesheets are grids of sprites with no metadata about where each sprite
sits. Guessing regions by eyeballing a downscaled image is unreliable — it
produced clipped/wrong sprites repeatedly. The workflow's rule:

> **Work from numbers and JSON, not from eyeballing images. Verify with the
> user at Phase A and Phase B before committing to scene/TileSet generation.**

Every step renders something the user can check; nothing is generated until the
tiling and the extracted sprites are both confirmed.

## Phase A — Inventory & propose the tiling

1. **Render the sheet gridded.** `tools/render_atlas_with_grid.gd` overlays a
   16-px grid + pixel coordinates so you can read off regions.
2. **Write a tiling JSON.** Lives in `levels/decorations/`. Two flavours:
   - **Props** (discrete objects): `<sheet>_props.json` — `props: [{ name,
     rect: [x,y,w,h], obstacle, flat }]`.
   - **Terrain** (autotile blocks): `<sheet>_tiles_blocks.json` — `blocks:
     [{ name, cells: [col,row,w,h] }]`, sizes in 16-px tile units.
3. **Render the proposal overlaid.**
   - Props: `tools/render_atlas_tiling.gd` draws each prop rect labelled.
   - Terrain: `tools/render_atlas_blocks.gd` draws each block + cell row/col
     numbers (supports a `view` crop window for high-zoom inspection).
4. **Show the user, iterate.** The user corrects boundaries by cell coords.
   Re-render until the tiling is right. *Do not proceed until confirmed.*

## Phase B — Extract & verify the sprites

5. **Render each extracted sprite isolated.** `tools/render_prop_previews.gd`
   renders every prop from the JSON as a clean, zoomed, labelled grid cell.
6. **Show the user.** Each sprite must look correct — no clipping, no atlas
   bleed. Iterate on Phase-A rects if any are wrong. *Confirm before Phase C.*

## Phase C — Table of Contents

7. **Generate a ToC** next to the spritesheet (`<SHEET>_TOC.md` + a
   `<SHEET>_TOC.png` reference render). Lists every sprite/block with name,
   region, size, and metadata (obstacle? terrain id? deferred?). This is the
   durable catalogue future work reads. Examples: `PROPS_TOC.md`,
   `TILES_TOC.md` in the Green Woods asset folder.

## Phase D — Generate the assets

**Props** → scene files:
- `tools/generate_prop_scenes.gd` reads the props JSON and emits one
  `prop_<name>.tscn` per entry. Obstacle props get `StaticBody2D` +
  `CollisionShape2D`; passable props are bare `Sprite2D`. `flat` props (flower
  patches / ground decals) anchor at the sprite's top edge so they y-sort as
  flat ground; upright props anchor at their base.
- Verify with `tools/render_decoration_grid.gd` (renders every decoration
  `.tscn` in a directory as a labelled grid).

**Terrain** → registered TileSet terrains:
- `tools/register_terrains.gd` reads the blocks JSON (`terrains` list +
  per-block `register` entry) and writes terrain data into the `.tres` TileSet:
  - `autotile3x3` — a 3×3 minimal autotile; the 9 peering configs follow a
    fixed pattern from inside/outside terrain ids.
  - `plain` — interchangeable centre tiles for fill variety.
- Back up the `.tres` first (the tool mutates it). Verify by painting a test
  region and rendering.
- **Don't** register loud detail tiles (e.g. rock-speckled grass) as fill
  variety — uniform random placement reads as noise. `probability` is *not*
  respected by terrain tile-selection.

## Tools

| Tool | Purpose |
|---|---|
| `render_atlas_with_grid.gd` | Sheet + 16-px grid + pixel coords |
| `render_atlas_tiling.gd` | Sheet + proposed prop rects overlaid |
| `render_atlas_blocks.gd` | Sheet + proposed terrain blocks + cell numbers (crop window supported) |
| `render_atlas_region.gd` | Sheet + a single region rect highlighted (debug one rect) |
| `render_prop_previews.gd` | Each prop from a JSON, isolated + zoomed + labelled |
| `render_decoration_grid.gd` | Every decoration `.tscn` in a dir, labelled grid |
| `generate_prop_scenes.gd` | Props JSON → `prop_*.tscn` files |
| `register_terrains.gd` | Blocks JSON → terrains written into a TileSet |

All render tools need a real GPU context — run under `xvfb-run -a` if headless.
