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
  ]
}
```

- `acquired_skills`: list of skill `.tres` basenames (e.g. `"heal"` → looks up `res://skill_tree/actions/heal.tres` via SkillManager). Also supports literal string `"full"` for "all skills."
- `starting_health` / `starting_position`: optional overrides; null = use defaults.
- `seed`: nonzero for reproducibility; required for batch comparisons later.

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
  "config": { /* echoes the input config verbatim */ },
  "outcome": "victory",
  "victory_type": "KILL_ALL_ENEMIES",
  "loss_type": null,
  "elapsed_seconds": 23.5,
  "characters": [
    {"name": "Puffin", "hp_final": 18, "hp_max": 30, "alive": true}
  ],
  "enemies": {
    "spawned": 12,
    "killed": 12,
    "alive_final": 0
  },
  "xp_gained": 50
}
```

Config is echoed inside summary so each summary is fully self-contained — you can diff just summaries between attempts to see what changed.

The live `LoggingComponent` stream (BEHAVIOR + HEALTH by default) goes to stdout during the run so the AI can scan for "what went wrong" between attempts.

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

## What's NOT in MVP but worth knowing

- **Batch mode** (run N seeds, aggregate). Useful for "is this env effect making the game too easy across 10 runs?" Add when single-attempt iteration is working.
- **Spawner overrides** (`--spawner=<level>:<spawner>:<key>=<value>` or in config). Highest-leverage difficulty knob; add when we start tuning difficulty rather than just trying to beat levels.
- **Event stream** (JSONL) separate from summary. Add when the AI needs cross-actor causal analysis ("which enemy killed which character at what time").
- **Aggregator** (`tools/sim/aggregate.py`). Standalone Python script for post-hoc analysis. Add with batch mode.
- **Loss-attribution stats in summary.** On a loss, the summary currently only says "TOWER_DIED at 17.5s" — it can't tell you how close the loss was (how much damage characters dealt before dying, how many seconds away from killing the next enemy, who delivered the killing blow on the tower). Tracking damage-dealt-per-character and last-hit attribution in the summary would make losses much more informative for iteration. Note: this is purely a sim-side concern — giving in-game XP on losses doesn't work (infinite retries × any-XP = infinite XP).
