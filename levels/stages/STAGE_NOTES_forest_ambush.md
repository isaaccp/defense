# STAGE_NOTES: forest_ambush

**Intent:** A single melee corridor (like `forest_chokepoint`) **plus a side
pocket near the tower**. The defending team — held together as one unit — must
also watch a close flank. Tests attention/tempo: notice the pocket burst,
pivot to clear it, resume the corridor, all without the tower dying. NOT a
spatial split (two coupled heroes can't be in two places).

## Geometry (960×540)

- **Tower:** Column @ (235, 259).
- **Open corridor band:** y[195,325], full width — the column area + main
  corridor, continuous.
- **Top forest** (impassable): y[0,195], split by the pocket — left x[0,180],
  right x[320,960].
- **Pocket:** an open vertical slot x[180,320], y[0,195]. Opens into the
  corridor at y=195, directly above the column.
- **Bottom forest** (impassable): y[325,540], full width.
- **Starting positions:** (310,215), (310,300) — in the corridor, by the column.

## Spawn anchors (for level designers)

- **Main:** (650, 260) — corridor approach, ~415px from the column. The
  far-right (900, 260) corner is reachable but produces ~700px travel distance
  that pushes single-character defense beyond what's practical at this skill
  budget; the closer anchor keeps round-trip time within Charge's reach.
- **Pocket:** (250, 100) — inside the pocket slot, ~165px above the column.

## Tactical demands

### Supports
- **Column melee pressure** down the main corridor — as `forest_chokepoint`.
- **Close-flank tempo test** — a timed pocket burst near the tower forces a
  unified-team pivot. Pairs with the **Closest To Tower First** target sort
  (flankers near the column auto-become priority → team pivots, then resumes).

### Does NOT support
- **True two-flank split** — the pocket is deliberately *close* (~165px), not a
  separate distant front. Two synergy-locked heroes cannot split across the map.

## Level variants

Two scenes live on this stage, designed as a progression that teaches the
same lesson (pocket forces a pivot) at two intensities. Both verified via
`tools/sim/` (baseline = no-substrate behaviors, substrate =
preferred-target commitment + AoE + Charge).

### `ambush_corridor_pocket.tscn` — trickle pattern
- Main corridor: 10 grunts @ 2.5s interval, delay 1.0s
- Pocket: 3 grunts @ 1.5s interval, delay 15.0s
- **Baseline (simple behavior)**: scrapes a win (~42s), tower nearly dead
  (~10/200). Substrate wins decisively (~32s), tower ~175/200.
- **Tests**: "the trickle is survivable but punishing; substrate buys you
  margin." Designed as the first place the player meets a near-tower pocket.

### `ambush_waves.tscn` — burst pattern
- Three corridor waves of 4 grunts each (interval 0.4s) at delays 1, 10, 20
- One pocket burst of 3 grunts (interval 0.4s) at delay 15
- **Baseline (simple behavior)**: loses — knight holds the corridor but pocket
  wave kills the tower (~39s, ~12/15 enemies killed).
- **Substrate**: wins (~32s), kills all 15, tower at 90% — Sweeping Attack
  fires into wave clusters (the lateral arrangement that capsule AoEs need),
  Cleave landing one-shots, knight commits to pocket when Target Near Tower
  fires.
- **Tests**: "you actually need the AoE primitives" — the wave pattern is
  what makes Sweeping Attack worthwhile, and Consecrate has real moments
  too. Validates that the substrate built up through level 2 starts paying
  for itself when enemies arrive bunched.

## Verification

- Render: `tools/render_stage.gd`
- Zone coverage: `tools/audit_zones.gd`
- Behaviors / level outcomes: `tools/sim/configs/ambush_*.json`

## Quirks

- The pocket path (vertical) and corridor path (horizontal) form a T — two
  `TerrainRegion`s on the `GroundPainter`.
- The pocket is an `OPEN` zone embedded in the top forest; the corridor is
  `OPEN` + `deliberately_bare` (path-dominated).
