# Level System

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
└── XPComponent
```

## Level State Machine

`level.gd` runs four states in order:

1. **PREPARE** — Pre-combat setup. Currently places characters at `StartingPositions` automatically. Intended to become an interactive placement phase (not yet implemented).
2. **COMBAT** — Starts all actors (characters, enemies, spawners, towers). This is where gameplay happens.
3. **SUMMARY** — Victory/loss screen, XP reward.
4. **DONE** — Terminal state.

## Creating a New Level

The typical pattern is two nested scenes:

**1. Stage scene** — defines the map: NavigationPolygon, obstacles, starting positions, towers, victory/loss conditions. Inherits `base_level.tscn`.

**2. Spawner config scene** — defines which enemies spawn, how many, and at what rate. Inherits the stage scene.

This lets you reuse the same map layout with different enemy waves.

Example: `stages/forest_stage_right_side_open.tscn` (map) → `main/forest_open_on_right_area/one_grunt_spawner.tscn` (wave config).

### Starting Positions

Set `StartingPositions/First.position` and `StartingPositions/Second.position` in the editor. Characters are placed here at the start of COMBAT (or eventually by the player during PREPARE).

### Obstacles

Obstacles live in `YSorted/Decoration` as `StaticBody2D` scenes. They block both movement (physics collision) and pathfinding (they bake into the NavigationPolygon automatically at runtime via `source_geometry_mode`).

Available decoration scenes in `levels/decorations/`:
- `tree_green.tscn` — small tree, CircleShape2D radius 12
- `big_tree_green.tscn` — large tree, CircleShape2D radius 20
- `small_tree_green.tscn` — extra small tree

Add any of these as children of `YSorted/Decoration` in the stage scene. The NavMesh updates automatically.

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

## Navigation and Obstacles

All enemy and character movement uses Godot's `NavigationAgent2D`. The `NavigationRegion2D` in each level holds the navmesh polygon. **Any StaticBody2D placed in the scene is automatically baked into the navmesh**, so obstacles affect pathfinding for free — no extra setup needed.

This means:
- Melee enemies path around obstacles
- Ranged enemies can be blocked by obstacles (they still try to path to their target)
- Choke points, corridors, and cover all emerge from obstacle placement alone

## What's Not Yet Implemented

- **Player character placement** — the PREPARE state exists but currently auto-places characters at fixed `StartingPositions`. The intended flow is for the player to drag characters onto the map before combat starts.
- **More decoration variety** — only tree types exist. Other obstacle shapes (walls, rocks, barrels) would need new StaticBody2D scenes.
- **Dynamic spawn positions** — `SpawnPositionConfig` only supports `CONSTANT` (spawn at the spawner's position). Spread/random patterns are not yet implemented.
