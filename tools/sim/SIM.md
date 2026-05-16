# Sim — Headless Run Simulator (Design)

A CLI tool for headless level simulation, designed for balance work and meta-progression iteration. **The AI assistant is the player**: it reads stages, drafts behaviors, runs the sim, reads results, and iterates — the tool just provides the per-level execution engine.

This is the design we agreed on; status notes describe what's MVP vs. deferred.

## Capture findings as you go

**Whenever a sim session reveals something about the game's design** (a skill that's missing, a level that's unwinnable with the available skills, a behavior-system limitation, a balance issue), add it to [`SIM_FINDINGS.md`](SIM_FINDINGS.md) under a dated entry.

This file is purely for *game-side* improvements — things the user might want to change in skills, levels, the behavior system, etc. Tooling improvements stay in this doc's "What's NOT in MVP" section.

The point: the sim is a discovery tool. If you find something worth fixing in the game and don't write it down, the next session will rediscover it. Write it down even if you're not going to act on it now.

## Vision

The dev wants to drive level/skill/meta-progression design with simulated runs:

- Try a level → adjust behaviors / difficulty until challenging-but-beatable
- Move to next level (with new skills "unlocked" mentally by the AI) → iterate
- Eventually batch-simulate full runs (incl. environment effects) for balance validation

The dev is a strong programmer but finds *balancing* hard. The sim is the tool that makes balance work tractable.

## Architecture

**Stateless per-level engine.** Each invocation:
- Reads one JSON config (level + characters + behaviors + acquired skills)
- Runs that level once
- Writes one JSON summary next to the config

**The AI handles orchestration in conversation.** No persistent run state across invocations, no PickPolicy abstraction, no headless Run state machine driving. Meta-progression is reasoned about by the AI between tool calls.

This was a deliberate scope cut from the original Plan-agent design. The deferred pieces (full Run state machine driving, batch mode, interactive JSON-RPC, env effects) all become unnecessary in MVP because the AI's reasoning replaces them.

## Files

```
tools/sim/
  SIM.md                          This doc.
  sim.gd                          SceneTree bootstrap (one-liner — loads sim_runner.gd).
  sim_runner.gd                   Typed runner. Parses config, builds level + characters,
                                  runs combat, writes summary.
  sim_levels.tres                 Separate level provider for sim runs (does NOT touch
                                  levels/main/main_levels.tres — keep sim and live game
                                  isolated).
  configs/
    <name>.json                   Per-attempt configs. AI authors these.
    <name>.summary.json           Auto-written alongside each config after a run.
  behaviors/
    <name>.json                   Transient behavior specs (JSON, see schema below).
                                  AI authors freely; these are throwaway experiments.
                                  Production behaviors stay in behavior/resources/.
```

Invocation: `godot --headless -s tools/sim/sim.gd -- <config.json>`

## Config schema (`tools/sim/configs/<name>.json`)

```json
{
  "level": "res://levels/main/forest_open_on_right_area/one_grunt_spawner.tscn",
  "seed": 1,
  "max_seconds": 30,
  "characters": [
    {
      "character": "res://character/playable_characters/puffin_the_cleric.tres",
      "behavior": "res://tools/sim/behaviors/cleric_heal_priority.json",
      "acquired_skills": ["heal", "move_to", "sword_attack"],
      "starting_health": null,
      "starting_position": null
    }
  ],
  "notes": "attempt 3: tried Charge instead of Move To"
}
```

- `acquired_skills`: list of skill `.tres` basenames (e.g. `"heal"` → looks up `res://skill_tree/actions/heal.tres` via SkillManager). Also supports literal string `"full"` for "all skills."
- `starting_health` / `starting_position`: optional overrides; null = use defaults.
- `seed`: nonzero for reproducibility; required for batch comparisons later.
- `notes`: free-form string. Echoed at top level of summary for scanning. Use it to remember what each attempt was trying.

## Behavior schema (`tools/sim/behaviors/<name>.json`)

Translated to `StoredBehavior` at runtime by the sim runner.

Every skill slot (`action`, `target`, `sort`, `condition`) is an object with `name` and optional `params`. No string-sugar shortcut — uniform shape avoids "wait, does this take params?" mistakes.

```json
{
  "name": "cleric_heal_priority",
  "rules": [
    {
      "action": {"name": "Heal"},
      "target": {"name": "Self Or Ally"},
      "sort": null,
      "condition": {"name": "Target Health", "params": {"threshold": 50}}
    },
    {
      "action": {"name": "Sword Attack"},
      "target": {"name": "Enemy"},
      "sort": {"name": "Closest First"},
      "condition": {"name": "Always"}
    }
  ]
}
```

- `params` is omitted (or `{}`) when the skill takes none.
- `sort` is `null` when not applicable (e.g. for self-targeted actions).
- Skill `name` values match the in-game skill name (`Heal`, `Sword Attack`, etc.) — same identifiers the editor uses, resolved via `SkillManager`.

**Why JSON not `.tres`:** `.tres` behavior files have many cross-referenced sub_resource IDs, ext_resource ordering, etc. — hand-authoring them produces syntax-error churn. JSON is grep-friendly, diff-friendly, easy for the AI to author. If a sim experiment produces a behavior worth keeping in production, the user recreates it as a proper `.tres` in the editor.

## Summary schema (`<config>.summary.json`)

```json
{
  "config_path": "...",
  "notes": "attempt 3: tried Charge instead of Move To",
  "config": { /* echoes the input config verbatim */ },
  "outcome": "victory",
  "victory_type": "KILL_ALL_ENEMIES",
  "loss_type": null,
  "elapsed_seconds": 23.5,
  "characters": [
    {
      "name": "Puffin", "hp_final": 18, "hp_max": 30, "alive": true,
      "position": {"x": 411, "y": 240},
      "damage_dealt": 0, "damage_healed": 45, "enemies_killed": 0
      // on death: also "killed_by": "...", "death_position": {...}
    }
  ],
  "towers": [ /* same shape; included even if free'd on death */ ],
  "enemies": {"spawned": 12, "killed": 12, "alive_final": []},
  "xp_gained": 50,
  "events": [ /* see "Events digest" below */ ]
}
```

Config is echoed inside summary so each summary is fully self-contained — you can diff just summaries between attempts.

The live `LoggingComponent` stream (BEHAVIOR + HEALTH + DEATH by default, all with coordinate-tagged messages for rule transitions and deaths) goes to stdout during the run for scanning "what went wrong."

## Events digest

`summary.events` is a chronological list of high-signal events synthesized during the run — a "story of the run" you can scan before opening raw logs. Event kinds:

- `spawn` — `{actor, actor_key, at: {x, y}}`
- `death` — `{actor, actor_key, at: {x, y}, killed_by}`
- `low_hp` — `{actor, actor_key, hp_pct: 50|25, at: {x, y}}` — fires once per threshold per actor
- `victory` — `{victory_type}`
- `loss` — `{loss_type}`

Every event carries `t` (seconds since combat start) and `kind`. Same coordinate semantics as everywhere else (960×540 canvas).

## Config validation

Before running, the sim walks the config and reports every problem at once (instead of fail-rerun-fail-rerun):

- Missing or non-existent paths (level, characters, behaviors)
- Unknown skill basenames in `acquired_skills`
- Behavior rules that reference skills the character doesn't have in `acquired_skills` (when `acquired_skills` is a list — `"full"` bypasses this check)

If any error is found, the sim exits with code 1 and prints all errors.

## Comparing attempts

`tools/sim/diff.py` compares two summary JSONs side-by-side:

```
tools/sim/diff.py tools/sim/configs/lvl5_attempt_1.summary.json tools/sim/configs/lvl5_attempt_2.summary.json
```

Shows outcome delta, elapsed-time delta, per-character HP / damage_dealt / kills / killed_by deltas, enemy count deltas, and event-kind counts. Pairs actors by `name#index` so two `Godrick`s match correctly.

## Decisions locked in

- Separate `tools/sim/sim_levels.tres` (does not touch live `main_levels.tres`)
- Retry-with-same-behavior up to a cap (number TBD — propose 3)
- Per-character behavior assignment (each character object has its own `behavior` field)
- Summary written next to config (`<basename>.summary.json`)
- Skills specified as basenames (with `"full"` shortcut)
- Config echoed inside summary
- Behaviors as JSON specs under `tools/sim/behaviors/` (not `.tres`)

## MVP scope

Build:
- `tools/sim.gd` + `tools/sim_runner.gd` (bootstrap + typed-runner split, same pattern as playthrough)
- JSON config + JSON behavior parsing
- SkillTreeState builder from basename list (with `"full"` shortcut)
- Summary writer
- Sample `sim_levels.tres`

Don't build (deferred):
- Headless UI layer / Run state machine driving
- PickPolicy abstraction
- Persistent run state across invocations
- Batch mode / aggregator
- Interactive JSON-RPC
- Environment effects
- Spawner/victory overrides (start with what `tools/sim/sim_levels.tres` provides as-is)
- Pre-summarized "what went wrong" text view

## Open questions (non-blocking, resolve during impl)

- `OnlineMatch` autoload usage when instantiating Level outside the gameplay scene. The existing playthrough_runner already deals with this; reuse its approach.
- `time_scale` for faster sims. Defer — playthrough runs near real-time and it's been fine.
- `DecorationScatter.rng_seed=0` reproducibility. Audit on first use; for now accept that scatter-randomized stages produce slightly different obstacle layouts between sim runs.
- Pre-summarized text view for the AI. Probably worth adding as a v2 feature when the volume of attempts justifies it.

## What's in v1 (post-MVP)

Added after the first iteration session surfaced gaps. All in service of the inner loop ("write config → run → diagnose → adjust"):

- **`notes` field** in config, hoisted to top-level of summary for scanning.
- **Coordinate-tagged behavior transitions** — `BehaviorComponent` rule-change logs now include `@(x, y)`.
- **`DEATH` LogType** — `DeathHandlerComponent` logs a death event with position via the actor's `LoggingComponent`.
- **Loss attribution** — per-character `damage_dealt`, `damage_healed`, `enemies_killed`, plus `killed_by` + `death_position` on dead actors. Tower data is snapshotted at death (it free's on death, so the read happens via the `died` signal).
- **Config validation** — pre-flight walk reports every problem at once.
- **Events digest** (see above).
- **`tools/sim/diff.py`** for comparing two summaries — outcome, time, per-actor stat deltas, event counts, and per-actor event-timing deltas (spawn / low_hp_50 / low_hp_25 / death; deltas under 0.1s are suppressed as engine jitter).
- **`tools/sim/events.py <summary>`** — terse one-line printer for the events digest. Use `--kind death,low_hp` to filter. Fastest "what happened" scan.

## What's NOT in MVP but worth knowing

- **Batch mode** (run N seeds, aggregate). Useful for "is this env effect making the game too easy across 10 runs?" Add when single-attempt iteration is working.
- **Spawner overrides** (`--spawner=<level>:<spawner>:<key>=<value>` or in config). Highest-leverage difficulty knob; add when we start tuning difficulty rather than just trying to beat levels.
- **Event stream** (JSONL) separate from summary. Add when the AI needs cross-actor causal analysis ("which enemy killed which character at what time").
- **Aggregator** (`tools/sim/aggregate.py`). Standalone Python script for post-hoc analysis. Add with batch mode.
- **Loss-attribution stats in summary.** Done in v1 (see "What's in v1" above).
- **One-line events digest format.** Done in v1 (`tools/sim/events.py`).
- **Per-actor timing deltas in diff.** Done in v1 (`diff.py` now emits "event timings" section with per-actor spawn/low_hp/death deltas, thresholded at 0.1s).
