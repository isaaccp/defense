# Level Design Playbook

A level = a stage (terrain) + spawner configuration (which enemies, how many, when, from where). See [LEVEL.md](LEVEL.md) for the stage/level split and [STAGE_DESIGN.md](STAGE_DESIGN.md) for the stage-design playbook (a prerequisite — you need a stage that hosts the tactical problem before you design levels on it).

This doc captures **how to design a balanced level**. Follow it before opening the editor or running `tools/new_level.gd`. Each new level should produce a `LEVEL_NOTES_<name>.md` (or comment block) answering the questions below.

## The 4 questions (answer before building)

1. **What is the level's intent in one sentence?** Examples: "force the team to split focus between flanks", "punish ignoring ranged threats", "test cooldown management under sustained pressure", "showcase AoE skills against a tight enemy cluster." If the intent overlaps an existing level, sharpen it or skip — don't ship a level whose problem is already solved.

2. **Which stage hosts this intent?** See `levels/stages/` and each stage's `STAGE_NOTES_*.md`. If no existing stage poses the right problem, **stop**: this is a Phase 2 task (build a stage first). Don't try to wedge a wrong-shape problem onto an unsuited stage.

3. **What enemy composition produces the intent?** See [enemies/ENEMIES.md](../enemies/ENEMIES.md) for the roster. Project design principle: **difficulty comes from composition, not per-level behavior changes**. Each enemy type has fixed behavior across all levels; you compose them to create the puzzle. Notes:
   - Prefer reusing tested combos before inventing new ones.
   - Use unused enemies (Skeleton Warrior, Skeleton Mage) before re-using overused ones.
   - Multiple ENEMY TYPES > more of the same type. Variety produces interesting decisions; volume produces fatigue.

4. **Where do they spawn, when, and how fast?** Spawner positions are the only stage-independent difficulty lever for a given stage. Cluster spawners for "wave that requires focus"; spread them across flanks for "split attention." `interval` + `amount` + `initial_delay` set the rhythm — short interval forces continuous pressure; long interval lets the team breathe between waves.

## Building the level

```bash
godot --headless -s tools/new_level.gd -- res://levels/stages/<stage>.tscn <level_name> [subdir]
```

Default output: `res://levels/main/<stage_basename>/<level_name>.tscn`. The scaffold gives you a bare scene inheriting the stage; you add spawner children manually.

### Spawner config — the .tscn pattern

Spawners are not as scriptable as the rest of the system, so they're fiddly to author by hand. Copy this pattern (taken from [chokepoint_debug.tscn](main/forest_chokepoint/chokepoint_debug.tscn)):

```ini
[gd_scene load_steps=8 format=3 uid="uid://<auto>"]

[ext_resource type="PackedScene" uid="uid://<stage-uid>" path="res://levels/stages/<stage>.tscn" id="1_stage"]
[ext_resource type="PackedScene" uid="uid://cnsf1muqgpiu1" path="res://spawners/portal_spawner.tscn" id="2_spawner"]
[ext_resource type="PackedScene" uid="uid://dndkag2tc2ltn" path="res://spawners/components/spawn_config_component.tscn" id="3_cfg"]
[ext_resource type="Script" path="res://spawners/components/data_types/spawn_provider_config.gd" id="4_prov"]
[ext_resource type="PackedScene" uid="uid://<enemy-scene-uid>" path="res://enemies/<enemy>/<enemy>.tscn" id="5_enemy"]
[ext_resource type="Script" path="res://spawners/components/data_types/spawn_placer_config.gd" id="6_plac"]

[sub_resource type="Resource" id="Resource_prov_a"]
script = ExtResource("4_prov")
spawn = ExtResource("5_enemy")

[sub_resource type="Resource" id="Resource_plac_a"]
script = ExtResource("6_plac")
amount = 5
interval = 2.0
initial_delay = 1.0

[node name="Level" instance=ExtResource("1_stage")]

[node name="MySpawner" parent="YSorted/Spawners" index="0" node_paths=PackedStringArray("placement_node") instance=ExtResource("2_spawner")]
position = Vector2(900, 260)
placement_node = NodePath("../../Enemies")

[node name="SpawnConfigComponent" parent="YSorted/Spawners/MySpawner" index="5" instance=ExtResource("3_cfg")]
spawn_provider_config = SubResource("Resource_prov_a")
spawn_placer_config = SubResource("Resource_plac_a")
```

For multiple spawners, repeat the spawner node + its SpawnConfigComponent + the two SubResources (use distinct ids like `Resource_prov_b` / `Resource_plac_b`).

### Knob reference

| Knob | Where | Effect |
|---|---|---|
| `position` (on spawner node) | spawner .tscn line | Where enemies appear in world. Highest-leverage knob. |
| `amount` | SpawnPlacerConfig | Total enemies spawned over the wave |
| `interval` | SpawnPlacerConfig | Seconds between spawns |
| `initial_delay` | SpawnPlacerConfig | Seconds before first spawn |
| `spawn` | SpawnProviderConfig | Which enemy scene (legacy PackedScene path) |
| `spawn_enemy_config` | SpawnProviderConfig | Which enemy config (newer EnemyConfig .tres path; `orc_warrior_spawner.tscn` uses this) |

Use **path-only ext_resources** for `.gd` scripts (no `uid=`). See the script-UID gotcha in [STAGE_DESIGN.md](STAGE_DESIGN.md#authoring-tscn-ext_resources-by-hand-critical-gotcha) — same trap applies here.

### Register the level

If the level should appear in real runs, add it to [`levels/main/main_levels.tres`](main/main_levels.tres). For sim-only experiments, skip registration.

## Verification (the 3-mode sim protocol)

A level is "balanced" when **all three modes pass**. Don't ship on a single sim run.

### Mode A — Feasibility (1 invocation)

Confirm the level is winnable at all. One config with starting-kit characters and a "reasonable best effort" behavior:

```bash
godot --headless -s tools/sim/sim.gd -- tools/sim/configs/<level>_mode_a.json
```

If this fails after 3 distinct behavior attempts (different rules, different positions), **the level is overtuned** — reduce enemy count, raise `initial_delay`, or drop an enemy tier (warrior → grunt). Don't try to fix the level by writing increasingly clever behaviors; that's the player's problem, not the level designer's.

### Mode B — Robustness (5 seeds × 2 comps)

Verify wins aren't seed-luck. Two character combos, each across seeds 1–5 (currently 10 manual invocations — `--seed N` flag). Score from `events.py` outcomes + summary `outcome` field:

| Win rate | Verdict |
|---|---|
| 8–10 / 10 | Too easy — raise difficulty |
| 0–1 / 10 | Too hard — lower difficulty |
| 4–7 / 10 | Balanced |
| Comps win at different rates that reflect intended tactical demand | Also balanced (e.g. AoE-required level should favor knight, fail for ranged-only comps) |

When this becomes the bottleneck, that's the signal to build batch mode (see [SIM.md](../tools/sim/SIM.md) "What's NOT in MVP").

### Mode C — Progression sanity (run sequence)

After a level set ships, simulate the **sequence** the player faces: lvl1 → lvl2 → ... → new level, with `acquired_skills` growing per step to mimic skill-tree progression. Look for difficulty cliffs in `elapsed_seconds` and damage taken across summaries. A 5× jump in time-to-win or damage-dealt between adjacent levels is a cliff; flatten it.

## Capturing per-level notes

For each level, write a `LEVEL_NOTES_<name>.md` sibling (or top-of-file comment) with:
- The 1-sentence intent
- Final enemy composition + spawn config
- Verification dates + summary file paths (Mode A/B/C)
- Win-rate band observed (Mode B)
- Any quirks future-you will want to remember

## When to stop iterating

- **3 attempts to win Mode A, all losses** → level is overtuned, simplify.
- **5+ attempts to balance Mode B, win-rate keeps flipping between extremes** → the level's design is unstable (small enemy-count changes cause huge outcome swings). Often means a single threat is load-bearing — split it into two smaller threats, or change the enemy mix.
- **Mode C shows a cliff** → either flatten the prior level (make it harder) or this level (make it easier). Prefer flattening the new one; existing levels are tuning baselines.

## What "balanced" doesn't mean

It does NOT mean every comp wins reliably. A level designed to test ranged-counterplay SHOULD be hard for melee-only comps. The goal is **intentional difficulty** — the comps that match the level's intent succeed, the comps that don't struggle. Mode B's "comps win at different rates reflecting intended tactical demand" captures this.
