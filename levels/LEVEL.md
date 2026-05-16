# Level System

## Coordinate Reference

| | Value |
|---|---|
| World canvas | **960 × 540** (set by [`gameplay.tscn`](../gameplay.tscn) `SubViewport.size_2d_override`; stretched to 1920×1080 at 2×) |
| Tile size | 16 × 16 px |
| Center | (480, 270) |
| Corners | top-left (0, 0), bottom-right (960, 540) |
| Character collision | CircleShape2D radius 10, offset (0, 5) from `position` (so `position` ≈ head, collision ≈ body) |
| `tree_green` radius | 12 |
| `big_tree_green` radius | 20 |
| `small_tree_green` radius | 10 (default) |
| Default `PlacementZone` | full canvas (0, 0) – (960, 540) |

Use [`tools/inspect_stage.gd`](../tools/inspect_stage.gd) to dump positions/bounds of an existing stage when designing a new one.

## Scene Hierarchy

All levels inherit from `base_level.tscn`. The full node structure:

```
Level (level.gd)
├── TileMap                        # Floor/background tileset
├── StartingPositions (Node2D)     # Where characters spawn
│   ├── First (Node2D)
│   └── Second (Node2D)
├── YSorted (Node2D)               # Y-sort container for depth ordering
│   ├── Characters (Node2D)        # Player characters
│   ├── Enemies (Node2D)           # Enemy actors
│   ├── Towers (Node2D)            # Towers / static structures
│   ├── Decoration (Node2D)        # Obstacles (trees, etc.)
│   └── Spawners (Node2D)          # Enemy spawner nodes
├── NavigationRegion2D             # Navmesh for all pathfinding
├── VictoryLossConditionComponent
├── XPComponent
└── PlacementComponent (Node2D)    # Where characters may be placed in PREPARE
    └── DefaultZone (Polygon2D)    # One or more PlacementZone children
```

## Level State Machine

`level.gd` runs four states in order:

1. **PREPARE** — Pre-combat setup. Characters are first placed at `StartingPositions`, then during PREPARE the player can drag them within the `PlacementComponent` zones before pressing Ready.
2. **COMBAT** — Starts all actors (characters, enemies, spawners, towers). This is where gameplay happens.
3. **SUMMARY** — Victory/loss screen, XP reward.
4. **DONE** — Terminal state.

## Creating a New Level

A **level** is what the player plays: a specific enemy wave on a specific map. A **terrain** is the reusable map base (layout, obstacles, starting positions). The typical pattern is two nested scenes:

**1. Terrain scene** — defines the map: NavigationPolygon, obstacles, starting positions, towers, victory/loss conditions. Inherits `base_level.tscn`. Lives in `levels/stages/`.

**2. Level scene** — defines the enemy wave: which enemies spawn, how many, at what rate. Inherits the terrain scene. Lives in `levels/main/`.

This lets multiple levels share the same terrain with different waves.

Example: `stages/forest_stage_right_side_open.tscn` (terrain) → `main/forest_open_on_right_area/one_grunt_spawner.tscn` (level).

### Registering a Level in the Game

A new level scene won't appear in the run until it is added to `levels/main/main_levels.tres`. Open that resource in the editor and append your scene to the levels array.

### NavigationPolygon for New Terrains

The default NavigationPolygon lives in `base_level.tscn`. A new terrain with a different shape or playable area must override it: select the `NavigationRegion2D` node in your terrain scene, click the polygon property to create a new one, and draw the walkable area in the editor. Obstacles placed in `YSorted/Decoration` are then automatically subtracted from it at runtime — you only need to draw the outer boundary.

### Starting Positions

Set `StartingPositions/First.position` and `StartingPositions/Second.position` in the editor. Characters are placed here at level load. During PREPARE the player can drag them inside any `PlacementZone` before pressing Ready (see below).

### Placement Zones

`PlacementComponent` holds one or more `PlacementZone` (Polygon2D) children defining where the player may place characters during PREPARE. `base_level.tscn` ships with a single `DefaultZone` covering the full play area; stages override this for tighter or disjoint placement areas.

To restrict placement on a stage: select the `PlacementComponent` node and replace or add `PlacementZone` children, drawing each polygon in the editor. Multiple disjoint zones are supported — `PlacementComponent.contains(point)` returns true if any child zone contains the point, and out-of-bounds drops are clamped to the nearest zone edge.

Zones are hidden during gameplay; they are shown (semi-transparent fill) only during PREPARE.

Drag-placement is currently single-player only. In online matches characters stay at `StartingPositions`.

### Obstacles

Obstacles live in `YSorted/Decoration` as `StaticBody2D` scenes. They block both movement (physics collision) and pathfinding (they bake into the NavigationPolygon automatically at runtime via `source_geometry_mode`).

Available decoration scenes in `levels/decorations/`:
- `tree_green.tscn` — small tree, CircleShape2D radius 12
- `big_tree_green.tscn` — large tree, CircleShape2D radius 20
- `small_tree_green.tscn` — extra small tree

Add any of these as children of `YSorted/Decoration` in the stage scene. The NavMesh updates automatically.

#### Scattering obstacles in bulk

For stages with many obstacles, [`DecorationScatter`](decorations/decoration_scatter.gd) replaces 20-50 hand-placed decoration positions with a single configurable node. Add it as a child of `YSorted/Decoration` and set:

| Property | Meaning |
|---|---|
| `decoration` | PackedScene to instantiate (e.g. `tree_green.tscn`) |
| `count` | how many to place |
| `area` | a `ScatterArea` resource defining where to scatter |
| `rng_seed` | 0 = random each load, nonzero = deterministic |
| `min_distance` | minimum spacing between instances, 0 = no constraint |

Available area shapes (all in [`decorations/scatter_areas/`](decorations/scatter_areas/)):

| Resource | Fields | Use for |
|---|---|---|
| `RectScatterArea` | `rect: Rect2` | rectangular patches, forest edges |
| `CircleScatterArea` | `center`, `radius` | round clearings, blob clusters |
| `AnnulusScatterArea` | `center`, `inner_radius`, `outer_radius` | ring around an open area |

Add new shapes by extending `ScatterArea` and overriding `random_point(rng)`.

Children are spawned at `_ready` and not serialized into the .tscn — only the scatter node and its config. In the editor, the scatter regenerates live as you tweak any property. The "Regenerate (new seed)" button rolls a fresh `rng_seed` — click until you like the layout, then save the scene with that seed locked in. The node shows an editor warning until `decoration` and `area` are both set. Multiple scatter nodes can coexist for layered patterns (e.g. dense forest edge + sparse interior).

### Spawners

Spawners live in `YSorted/Spawners`. Each spawner is a `portal_spawner.tscn` or `spawner.tscn` instance with a `SpawnConfigComponent` child that carries three config resources:

| Config resource | Key properties |
|---|---|
| `SpawnProviderConfig` | `spawn`: PackedScene (enemy .tscn) |
| `SpawnPlacerConfig` | `amount`, `interval` (seconds between spawns), `initial_delay` |
| `SpawnPositionConfig` | spawn offset pattern (currently only `CONSTANT = Vector2.ZERO`) |

Spawners are placed by the level designer at any position in the scene. Enemies spawn at the spawner's world position.

### Victory / Loss Conditions

Set on `VictoryLossConditionComponent`. Multiple conditions can be active simultaneously.

**Victory types:** `KILL_ALL_ENEMIES`, `ONE_REACH_POSITION`, `ALL_REACH_POSITION`, `TIME`

**Loss types:** `ANY_CHARACTER_DIED`, `ALL_CHARACTERS_DIED`, `TOWER_DIED`, `TIME`

The most common setup is `KILL_ALL_ENEMIES` + `ALL_CHARACTERS_DIED`.

### XP Rewards

`XPComponent` awards `base_xp` modified by a speed multiplier:

| Time since last spawn | Multiplier |
|---|---|
| < 15s | 2× |
| < 30s | 1.5× |
| < 60s | 1× |
| > 60s | 0.5× |

## Inspecting a Stage from the CLI

[`tools/inspect_stage.gd`](../tools/inspect_stage.gd) dumps a one-screen summary of any level/stage scene — useful when working without the editor (e.g. from an AI agent). Run:

```
godot --headless -s tools/inspect_stage.gd -- res://levels/stages/forest_stage_right_side_open.tscn
```

Output shows starting positions, towers, decoration counts + bounding box, spawner configs (enemy/amount/interval), placement zone rectangles, and victory/loss conditions — all from the loaded scene, no `.tscn` parsing.

## Navigation and Obstacles

All enemy and character movement uses Godot's `NavigationAgent2D`. The `NavigationRegion2D` in each level holds the navmesh polygon. **Any StaticBody2D placed in the scene is automatically baked into the navmesh**, so obstacles affect pathfinding for free — no extra setup needed.

This means:
- Melee enemies path around obstacles
- Ranged enemies can be blocked by obstacles (they still try to path to their target)
- Choke points, corridors, and cover all emerge from obstacle placement alone

## What's Not Yet Implemented

- **Online drag-placement** — single-player placement is wired; in online matches characters still use `StartingPositions`. A follow-up should RPC the final position on drop.
- **More decoration variety** — only tree types exist. Other obstacle shapes (walls, rocks, barrels) would need new StaticBody2D scenes.
- **Dynamic spawn positions** — `SpawnPositionConfig` only supports `CONSTANT` (spawn at the spawner's position). Spread/random patterns are not yet implemented.
