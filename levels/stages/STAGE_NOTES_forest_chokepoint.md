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

## Tactical demands

Derived **from the numeric geometry above**, not feel. If you want to add a "supports" or "does NOT support" row, do the math first and show it.

### Supports

- **Column pressure** — single corridor approach, enemies forced into a sustained engagement line in front of the tower. The base "rush" pattern.
- **AoE-favoring fights** — corridor width (130px) clusters enemies tightly; Cleave / Sweeping Attack / Fire Burst hit multiple targets reliably.
- **Doubled column pressure** — two spawners 120px apart still funnel into the same engagement zone (the corridor is 130px wide, and starting positions are 120px apart at y=200/320). Net effect = more enemies per second from a single front, not two distinct fronts. Use when you want denser cadence than a single spawner allows.
- **Melee chokepoint** — characters in the corridor mouth can block enemy melee approach physically.
- **Tower-vulnerable approaches** — direct corridor line to (235, 259); enemies that slip through reach tower fast.

### Does NOT support

- **True two-flank pressure** — would require characters to defend physically separate fronts. **Math:** corridor is 130px tall; starting positions y=200 and y=320 are only 120px apart; spawn anchors y=200/320 same spread. There is no flank — there's a single 130-px-wide front. Two spawners at corridor edges produce *doubled column pressure*, not flanks. Build a wider/divided stage for real two-flank designs.
- **Ranged kiting from flanks** — flanking trees block LoS by design (the original intent), so ranged enemies can't fire from off-axis. Archers in this stage effectively become melee-range threats that throw projectiles.
- **Long approach reaction window** — corridor mouth-to-tower distance is short (~365px from y=260 corridor center to tower at x=235); slow walkers reach the engagement zone quickly. Fights wanting a "see them coming, prepare" beat want a different stage.

## Quirks worth remembering

- DecorationScatter uses fixed seeds — re-running won't change tree positions unless seed is changed.
- Tower is at the corridor's left mouth, exposed to direct corridor approach but not to flank fire.
- Cleric's new `Sword Attack` (Phase 1D) can shine here — adjacent enemies in the corridor mean she can swing while healing.
