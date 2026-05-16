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

## Priority 1 — Level Variety via Obstacles and Stage Design

Player drag-placement during PREPARE is now wired (single-player only — online still uses `StartingPositions`). Multiple disjoint `PlacementZone` children of `PlacementComponent` let stages restrict placement, so stage layout now has real strategic weight.

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

## Priority 2 — Add Unused Enemies to Main Levels

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

## Behavior System — Design Ideas (parking lot)

Captured from sim sessions (see [`tools/sim/SIM_FINDINGS.md`](tools/sim/SIM_FINDINGS.md)) and design discussions. Not prioritized — these are pointers for future thinking, not specs.

### Resource cost for skills (stamina pool?)

**Problem:** skill cooldowns are per-skill and independent. A character with 5 skills can fire one cast every ~1s on average; a character with 10 skills can fire one cast every ~0.5s. **Adding skills passively increases throughput** — wider trees are strictly better than narrower trees, which makes balancing skill acquisition hard.

**Idea:** a shared stamina pool per character. Each skill consumes stamina on use; stamina regenerates over time. Stamina caps throughput regardless of skill count.

**Open question:** managing stamina under the "first-rule-matches-wins" model is awkward — the rule that wants to fire might not have enough stamina, and there's no obvious "wait until stamina is ready" pattern in the current rule grammar. Possible workarounds: a `Stamina >= N` condition, an implicit "skip if insufficient stamina" semantic, or pair with the tables-and-jumps idea below.

### Richer target sorts and threat conditions

Current sort orders are limited to `Closest First` / `Farthest First`. Sims showed this is too coarse — you can't say "kill the archer that's currently shooting the tower."

Suggested additions (most are easy on top of existing per-actor stats):

- **`Lowest Health First`** — finish wounded enemies efficiently.
- **`Highest Threat`** — sort by DPS dealt to friendlies / tower, derived from existing stats tracking.
- **`Highest Threat (ranged)`** / **`Highest Threat (melee)`** — same, filtered by attack type. There's already an `ActionTag` system and `AttackType` info, but it's hidden inside projectile definitions rather than surfaced on the action itself. Surfacing it on the action would let target sorts and conditions filter by it directly. Alternatively, derive from stats: "Highest ranged-damage dealer" is computable from damage logs without needing the tag to be on the action.
- **Conditions like `Attacking Tower`** / **`Attacking Me`** — filter to enemies based on what they're currently doing.

**Caveat:** even with these, behaviors can pick suboptimal targets (e.g. chasing a far ranged threat while the tower gets destroyed at home). Targeting alone doesn't solve positional strategy — that's a separate problem (movement / hold-position logic).

### Multiple behavior tables with jumps (function-like)

**Problem:** first-match-wins rule ordering is clean and predictable, but complex behaviors (defensive mode, aggro mode, retreat mode) all squeezed into one ordered list become brittle and hard to read.

**Idea:** allow multiple named rule tables, plus a meta-skill that jumps to a different table, plus a condition to return to the main table. Effectively turns behaviors into a small state machine — each table is a "function" or "mode" the character is currently in.

Example shape (sketch):
- Main table: standard combat rules
- `Defensive` table: triggered when HP < 30%, kites and heals
- A `Switch to Defensive` rule in the main table jumps when the condition fires
- A `Return to Main` rule in the Defensive table jumps back when HP > 60%

This is more expressive than a flat priority list and composes well with the stamina idea (different tables = different rhythms).

---

## Priority 3 — Run Variety via Environmental Effects (later)

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
