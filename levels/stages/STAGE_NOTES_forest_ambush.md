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

- **Main:** (900, 260) — right end of the corridor.
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

## Verification

- Render: `tools/render_stage.gd`
- Zone coverage: `tools/audit_zones.gd`
- Levels: pair a steady corridor spawner with a timed pocket-spawner burst.

## Quirks

- The pocket path (vertical) and corridor path (horizontal) form a T — two
  `TerrainRegion`s on the `GroundPainter`.
- The pocket is an `OPEN` zone embedded in the top forest; the corridor is
  `OPEN` + `deliberately_bare` (path-dominated).
