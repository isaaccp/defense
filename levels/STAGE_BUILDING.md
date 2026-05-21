# Stage Building

How a stage's *visuals* are assembled — ground terrain, zones, decoration —
once the spritesheet assets exist (see [SPRITESHEET_WORKFLOW.md](SPRITESHEET_WORKFLOW.md))
and the gameplay layout is decided (see [STAGE_DESIGN.md](STAGE_DESIGN.md)).

## The model

A stage `.tscn` inherits `base_level.tscn`. base_level ships an **empty**
TileMap — each stage paints its own ground. The stage `.tscn` is the single
source of truth: it carries config nodes that regenerate their output at
`_ready` (in the editor too). Nothing is baked into the saved file.

Three config-node types do the work:

- **`GroundPainter`** — paints the TileMap (grass fill + terrain regions).
- **`Zone`** — declares a named region of the stage with a `kind`.
- **`DecorationScatter`** — scatters decoration props inside a zone.

## Zones

Every part of a stage belongs to a declared `Zone`. Zones make decoration
coverage *auditable* instead of ad-hoc.

A `Zone` has:
- **`kind`**:
  - `OPEN` — walkable gameplay space. Random scatter must not drop colliding
    props here (it would silently change the strategy), so colliding props are
    filtered out of scatter pools automatically.
  - `ENCLOSED` — walled off from gameplay (tree-walls, a fenced yard). Scatter
    may place anything, colliding props included.
  - `SOLID` — a building / solid-object footprint. No decoration at all.
- **`area`** — a `ScatterArea` (rect/circle/annulus).
- **`deliberately_bare`** — an `OPEN`/`ENCLOSED` zone that intentionally carries
  no decoration (e.g. a path-filled corridor). Suppresses the audit warning.

`DecorationScatter`s live **under** a Zone and inherit its `kind` (and `area`,
unless the scatter sets its own sub-region). One zone can hold several scatters
— e.g. a tree-wall zone with separate tree / obstacle / flower passes.

**Zones should tile the stage** (≥ 90% coverage). `tools/audit_zones.gd`
calculates coverage and flags any `OPEN`/`ENCLOSED` zone with no scatter that
isn't `deliberately_bare` — a pure calculation, no render needed.

## The build phases

**Phase 0 — gameplay layout.** Decide tower, spawns, the walkable corridor,
wall zones. Pure design (STAGE_DESIGN.md questions). Output: regions, not art.

**Phase 1 — ground.** Add a `GroundPainter`, point it at the TileMap. It fills
a `base_terrain` (grass) then paints `TerrainRegion`s on top (the path). The
path's shape must trace the actual corridor — a path that doesn't match the
walkable space misleads the player. **Paths must be ≥ 3 tiles wide** (the
grass/dirt autotile has no tile for a thinner strip).

**Phase 2 — structures (load-bearing).** Deliberately-placed,
navigation-affecting objects: tree-walls, fences, fountains, barricades. These
are reviewed and sim-verified — the level must play correctly before any
decoration. A colliding obstacle is fine *anywhere* as long as it's a
deliberate structure; what's not fine is random scatter dropping colliders into
the fight space.

**Phase 3 — decoration.** Add `Zone`s covering the whole stage, with
`DecorationScatter`s under the ones that should be decorated. Every `OPEN`/
`ENCLOSED` zone gets decoration unless `deliberately_bare`. `audit_zones.gd`
confirms coverage + completeness.

## DecorationScatter

- `decorations` — pool of prop scenes, picked uniformly at random.
- `count`, `rng_seed` — how many to place / determinism.
- `spacing` (0..1) — placement is Poisson-disk: a point is rejected if closer
  than `spacing × natural-spacing` to an existing one. 0 = pure random (clumps
  allowed); higher = even spacing with no clumps and no row/column structure.
  The gap relaxes automatically if `count` can't otherwise fit. (A jittered
  grid was tried first — it bands rows; Poisson-disk doesn't.)
- `companions` — small props clustered around each placed decoration
  (e.g. mushrooms at tree bases), kept inside the zone. `companion_chance` /
  `companion_count` / `companion_radius`. This is *scatter with intent* —
  thematic pairing instead of uniform speckle.
- In an `OPEN` zone, colliding props (anything with a `PhysicsBody2D` root) are
  filtered out of the decoration and companion pools.

Decoration density guidance: open fields sparse (leave breathing room), wall
zones denser. Uniform random placement of loud props reads as noise — prefer
clustering (companions) and sparse placement.

### Tall props below a path/objective — inset the scatter

y-sort draws a prop in front of anything with a smaller Y. A **tall prop in a
zone *below* a path or the tower** therefore y-sorts *in front* of it — and a
tree's canopy extends ~110px *upward* from its base, so that canopy is drawn
over the path/tower and hides them.

Fix: give that zone's tall-prop scatter its own `area`, **inset from the top
edge** by roughly the prop height — ~110px for trees, ~50px for bushes. The
canopies still fill the visual gap (they reach up); only the bases move down.
Flat props (flowers, anchored at their top edge — they draw *downward*) don't
need this. A zone *above* a path is fine — its props y-sort behind it.

## Verification

| Tool | Checks |
|---|---|
| `audit_zones.gd` | Zone coverage % + undecorated-zone flags (no render) |
| `render_zone_audit.gd` | Stage with Zone outlines + kinds overlaid |
| `render_stage.gd` | Plain render of the assembled stage |

## Tools

| Tool | Purpose |
|---|---|
| `render_stage.gd` | Render a stage/level `.tscn` to PNG |
| `render_zone_audit.gd` | Render a stage with Zone outlines overlaid |
| `audit_zones.gd` | Headless zone coverage + completeness audit |

Render tools need a real GPU context — run under `xvfb-run -a` if headless.

## Key scripts

- `levels/ground/ground_painter.gd` + `terrain_region.gd`
- `levels/zones/zone.gd`
- `levels/decorations/decoration_scatter.gd` + `scatter_areas/`
