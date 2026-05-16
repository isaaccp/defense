# STAGE_NOTES: forest_chokepoint

**Intent:** Force enemies through a narrow central corridor; reward AoE skills (Cleave, Sweeping Attack, Fire Burst) which have no good level on the open stage; explicitly break the "archers shred tower from flanks" failure mode that plagues every level on `forest_stage_right_side_open`.

## Geometry (960×540)

- **Tower:** Column @ (235, 259), inherited convention.
- **StartingPositions:** First @ (300, 200), Second @ (300, 320). Closer together than `forest_open` (which used y=179 / y=339) — fits the corridor mouth.
- **Decoration walls** (dense scatter, blocks LoS from upper/lower right to tower):
  - Top wall: rect (400, 0) to (920, 195), ~18 trees mixed sizes
  - Bottom wall: rect (400, 325) to (920, 540), ~18 trees mixed sizes
  - Corridor between walls: y ∈ [195, 325], ~130px tall by ~520px wide
- **Spawn anchors** (for level designers, not in stage):
  - Single anchor: (900, 260) — corridor center, "rush" levels
  - Two anchors: (900, 200) + (900, 320) — corridor edges, "two-pressure" levels
- **PlacementComponent:** default full-map zone; trees implicitly restrict useful placement.

## Verification

- Render: `/tmp/forest_chokepoint.png` (verify the corridor is visually obvious)
- Debug sim: retarget `one_grunt_spawner.tscn` onto this stage, expect clean win (proves NavMesh works around scattered trees)

## Quirks worth remembering

- DecorationScatter uses fixed seeds — re-running won't change tree positions unless seed is changed.
- Tower is at the corridor's left mouth, exposed to direct corridor approach but not to flank fire.
- Cleric's new `Sword Attack` (Phase 1D) can shine here — adjacent enemies in the corridor mean she can swing while healing.
