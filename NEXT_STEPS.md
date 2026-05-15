# Next Steps — Making the Game Fun

## Context

The core problem is that levels feel samey: a plain field, identical enemy behavior, and no meaningful player decisions during setup. The infrastructure for fixing all of this exists — it mainly needs content and one missing UI feature.

**What was recently done:**
- Orc Archer now kites (Bow Attack min 100, Move Away max 120, Move To fallback)
- Orc Berserker added (`enemies/orc_berserker/orc_berserker.tscn`) — Charge → Sword Attack → Move To, speed=45, hp=8
- Enemy smoke tests added (`tests/enemies/enemy_smoke_test.gd`)
- Documentation: `behavior/BEHAVIOR.md`, `enemies/ENEMIES.md`, `enemies/NEW_ENEMY.md`, `levels/LEVEL.md`

**Design principle:** enemy behavior is fixed per type across all levels. Difficulty comes from *composition* (which enemies, how many, spawn timing and direction) not per-level behavior changes. See `enemies/ENEMIES.md`.

---

## Priority 1 — Implement Player Character Placement

The PREPARE state already exists in `levels/level.gd` but currently auto-places characters at fixed `StartingPositions` nodes. The intended flow is for the player to drag characters onto the map before pressing ready.

This is worth doing first because it's a prerequisite for level variety to matter: if players can't choose where to stand, obstacle placement and spawn direction have no strategic weight.

**What to implement:**
- During PREPARE, show characters as draggable items the player places on the map
- Constrain placement to a valid zone (e.g. left half of the map, or explicit placement nodes)
- A "Ready" button transitions to COMBAT

**Relevant files:**
- `levels/level.gd` — PREPARE state is where this logic lives
- `levels/base_level.tscn` — has `StartingPositions/First` and `StartingPositions/Second` nodes (currently just fixed Vector2 positions)
- `ui/` — existing UI screens for reference on how screens are structured
- `run/run.gd` — run state machine that drives level transitions

---

## Priority 2 — Level Variety via Obstacles and Stage Design

Currently all main levels use a single stage (`forest_stage_right_side_open.tscn`) with trees scattered around an open area. Two levers available with no new infrastructure:

**A. More obstacle layouts within the existing stage**
Trees are `StaticBody2D` scenes in `YSorted/Decoration` — they automatically bake into the NavigationPolygon and block pathfinding. Rearranging them creates chokepoints, corridors, and cover with no code changes.

Ideas worth trying:
- A corridor down the middle with open flanks (rewards AoE characters)
- A cluster of trees blocking the direct path from one spawn point (forces enemies to path around)
- Sparse obstacles in the center (open field but with a few pillars breaking sightlines)

**B. New stage shapes**
A new stage is a scene extending `base_level.tscn` with a different NavigationPolygon, different tile layout, and different obstacle arrangement. See `levels/LEVEL.md` for the creation pattern.

Ideas:
- Narrow horizontal corridor (very different from the current open field)
- Two chokepoints with open flanks
- Enemies spawning from multiple sides

**Relevant files:**
- `levels/stages/forest_stage_right_side_open.tscn` — current only stage
- `levels/decorations/` — available obstacle scenes (tree_green, big_tree_green, small_tree_green)
- `levels/LEVEL.md` — full documentation of level structure and how NavMesh/obstacles work

---

## Priority 3 — Add Unused Enemies to Main Levels

Two fully implemented enemies are not used in any main level:

**Skeleton Warrior** (`enemies/skeleton_warrior/skeleton_warrior.tscn`) — HP 8, armor 2, speed 30. Sword Attack + Move To. The armor makes it meaningfully tankier than the Orc Grunt. Good for compositions that mix a durable frontliner with faster fodder.

**Skeleton Mage** (`enemies/skeleton_mage/skeleton_mage.tscn`) — HP 6, armor 0, speed 28. Seeks bolt (homing, min range 100, max 300) + Move To. The only arcane damage source. Creates a "kill the mage first" priority decision when mixed with melee.

Suggested compositions to try in new spawner config scenes:
- Skeleton Warrior + Orc Grunt — durable tank backed by fast fodder
- Skeleton Mage + any melee — ranged pressure from the back while melee closes
- Orc Archer + Skeleton Mage — two ranged types with different attack patterns
- Orc Berserker + Skeleton Warrior — fast charger plus armored backup

Add new spawner config scenes under `levels/main/` following the existing pattern (inherit a stage scene, add spawner children). See `levels/LEVEL.md`.

---

## Priority 4 — Run Variety via Environmental Effects (later)

Infrastructure already exists: damage types and actor attributes support per-run modifiers (e.g. "Neverending Storm: fire damage halved, lightning doubled"). This layer is not yet wired to the run selection flow.

Hold off until levels have interesting compositions — the variety layer only matters once the baseline puzzle is engaging.

---

## Key Files

| File | Purpose |
|---|---|
| `levels/LEVEL.md` | Level structure, spawner config, obstacles, NavMesh, what's not yet implemented |
| `enemies/ENEMIES.md` | Full roster: stats, behavior, current level usage |
| `enemies/NEW_ENEMY.md` | How to create a new enemy scene from scratch |
| `behavior/BEHAVIOR.md` | Behavior system: available skills, params, action lifecycle |
| `AGENTS.md` | Project overview, component system, directory map |
| `tests/enemies/enemy_smoke_test.gd` | Auto-discovering smoke tests for all enemy scenes |
