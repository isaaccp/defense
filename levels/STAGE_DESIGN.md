# Stage Design Playbook

A stage = a terrain (NavMesh, tower placement, starting positions, decorations, placement zones). Levels are stages with spawner configurations layered on top — see [LEVEL.md](LEVEL.md) for the stage/level split.

This doc captures **how to design a new stage that forces interesting decisions**. Follow it before opening the editor or running `tools/new_stage.gd`. Each new stage should produce a `STAGE_NOTES_<name>.md` (or comment block at top of the .tscn) that answers the 5 questions below.

## The 5 questions (answer before building)

1. **What tactical problem does this stage pose?** One sentence. Examples: "force the team to split between flanks", "punish stationary buff-stacking", "reward AoE and area-control", "create a defensible chokepoint." If you can't articulate this, the stage isn't designed yet — figure out the problem before building geometry.

2. **Where's the tower? Where are the starting positions?** Plot on the 960×540 grid. The convention is left-side defending right-side spawns, but a new stage can break this (top vs bottom, multi-tower, no-tower). Be explicit.

3. **Where will spawners likely be placed?** Stages don't own spawners, but tactical intent depends on rough spawn anchors. Sketch 2–4 plausible spawn anchors and note which level-types they'd serve (single-side rush, two-flank pressure, surround, etc.).

4. **What sight-lines exist between spawn anchors and the tower?** Decoration breaks line-of-sight; the existing `forest_open_on_right_area` has zero blockers between archer spawn anchors and the tower, which is why ranged-heavy levels there are unwinnable. Each new stage must consciously decide: where can ranged enemies see the tower from?

5. **What does the placement zone look like?** Restricting placement is the cheapest difficulty knob — a stage that forces you to start far from the tower changes the puzzle entirely. Decide if `PlacementComponent` should use the default full-map zone or restricted polygons.

## Authoring `.tscn` ext_resources by hand (critical gotcha)

When adding ext_resources to a `.tscn` (e.g. wiring up `DecorationScatter` with a `RectScatterArea` sub-resource), **omit the `uid="..."` field on script ext_resources**. Use path-only:

```
# Good (path-only — Godot resolves it):
[ext_resource type="Script" path="res://levels/decorations/decoration_scatter.gd" id="3_scatter"]

# Bad (UID + path — if the UID is wrong, Godot loads the WRONG script and tries
# to attach it to your node, giving cryptic "Script inherits from native type
# 'Resource', so it can't be assigned to an object of type 'Node2D'" errors):
[ext_resource type="Script" uid="uid://qe1dsul2aje7" path="res://levels/decorations/decoration_scatter.gd" id="3_scatter"]
```

For `PackedScene` ext_resources (towers, decorations), look up the UID from the `.tscn` header (first line) — these are reliable. For `Script` ext_resources, looking up `.uid` files by name is error-prone; just skip the UID and Godot will resolve by path. The path fallback is robust and produces only a one-time warning that clears after the editor rescans.

## Building the stage

```bash
godot --headless -s tools/new_stage.gd -- <stage_name>
```

Then edit `res://levels/stages/<stage_name>.tscn`:

- Update `StartingPositions/First` and `Second` positions.
- Add decorations under `YSorted/Decoration`. For dense patches, prefer `DecorationScatter` nodes (see `levels/decorations/scatter_areas/` for shape options) over hand-placed trees — much easier to iterate.
- If using restricted placement, edit `PlacementComponent` to replace `DefaultZone` or add additional zones.
- The NavMesh on `NavigationRegion2D` is inherited from `base_level.tscn`'s default (the full 960×540 canvas). Override only if the playable area is non-rectangular.

## Verification

A stage is "good enough to host levels" when **all three** pass:

1. **Inspect** — `tools/inspect_stage.gd` confirms the structure:
   ```bash
   godot --headless -s tools/inspect_stage.gd -- res://levels/stages/<stage>.tscn
   ```
   Should show expected StartingPositions, Tower, Decoration bounds, PlacementZone, no surprises.

2. **Render** — `tools/render_stage.gd` produces a PNG; visually the answer to question 1 is obvious:
   ```bash
   godot --path . -s tools/render_stage.gd -- res://levels/stages/<stage>.tscn /tmp/<stage>.png
   ```

3. **Debug sim** — retarget the simplest existing level (`one_grunt_spawner.tscn`) onto the new stage and sim it. A clean win proves enemies can path, characters can reach them, and the NavMesh isn't obstructed. Use a quick sim config; if it fails, the stage has a pathing bug, not a design issue.

## Capturing per-stage notes

For each stage, write a sibling `STAGE_NOTES_<name>.md` (or top-of-file comment) with:
- The 1-sentence intent
- Final answers to questions 2–5
- The verification rendered image (path)
- Any quirks future-you will want to remember

## What "the source of half our balance issues" looks like

The existing single stage (`forest_stage_right_side_open.tscn`) has:
- All starting positions on the left, all spawns on the right
- Trees only on the left half (no cover for tower from right-side ranged fire)
- Full-map placement zone
- Tower exposed in the middle-left

This is why every existing level has the same failure mode (archers shred tower from flanks). A second stage with **different geometry** unlocks tactical demands the current stage can't express. The point of a new stage is **not** to copy this layout — it's to demand things the existing one can't.
