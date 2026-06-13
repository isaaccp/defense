# Next Steps — Making the Game Fun

## Backlog (as of 2026-06-11)

Active backburner from the reward-stage + relic batch sessions. Older notes below this section predate the reward/relic/map work and may be stale.

### Reward stage UX

- **Trainer overlay still full-screen.** Loses reward-stage context (party cards, set panels) when SkillTreeUI opens. Embed it differently — maybe replacing only the right column.
- **Polish pass**: icons on reward cards, sounds, transition animations beyond the existing HP floaters and pulse.

### Bugs


### Relics

- ~~**Echoing Ward**~~ — Implemented.
- ~~**Spectral Echo**~~ — Dropped (too much action-specific coupling).
- ~~**Vampire's Tooth**~~ — Implemented.
- ~~**Spiked Pauldrons**~~ — Implemented.
- ~~**Executioner's Axe**~~ — Dropped (thematic mismatch).
- ~~**Overflowing Chalice**~~ — Implemented.
- ~~**Blood Frenzy**~~ — Implemented.
- ~~**Giant's Belt**~~ — Implemented.
- ~~**Focused Mind**~~ — Implemented (reworked to Juggler approach).
- ~~**Momentum Crystal**~~ — Implemented.

- **"Dozens of relics" goal**: Ongoing.

### Map / campaign

- **MT-style per-stage difficulty modifiers** — opt-in harder version of a fight for a better reward (Monster Train banner/covenant analog). The closest fit to STS's elective-risk-reward knob inside the MT structure we chose. Worth designing once the map basics are in.
- **Map UI rendering** — the actual on-screen map (current node, future nodes, branching if any). User has built similar before; treat as a self-contained task on the to-do list for Claude.
- **More reward types** — Rest / Relic / Trainer is the shipped set. Likely additions: events, shops, others. Each is just a new `RewardDef` subclass; no "node" concept to add since rewards aren't nodes in this design.

### Content + tooling gaps

- **Chest substrate is built but unused in any main_levels level.** Drop a chest into a real campaign level so the Interactable/Open/Gold flow gets exercised in actual play.
- **Gold has no UI.** Accumulates from chests into RunSaveState; never shown to the player.
- **Sim non-determinism on archer levels** (Move Away + NavigationAgent2D RVO). Documented in `tools/sim/SIM_FINDINGS.md`. Blocks batch-mode work.
- **d=3 levels lack recorded sim pair files** — only the d=1/d=2 levels have them in `tools/sim/behaviors/level/`. Catalog incomplete.
- **Class-relic vs earned-relic distinction on the character card** — they're now excluded from rewards but still rendered inline with earned relics on the HUD. Cosmetic.
- **Smoke-test the new relics in actual play** — they pass tests but haven't been exercised in a fight via the sim or F6.

---

## Context

The core problem is that levels feel samey: a plain field, identical enemy behavior, and no meaningful player decisions during setup. The infrastructure for fixing all of this exists — it mainly needs content and one missing UI feature.

**What was recently done:**
- Orc Archer now kites (Bow Attack min 100, Move Away max 120, Move To fallback)
- Orc Berserker added (`enemies/orc_berserker/orc_berserker.tscn`) — Charge → Sword Attack → Move To, speed=45, hp=8
- Enemy smoke tests added (`tests/enemies/enemy_smoke_test.gd`)
- Documentation: `behavior/BEHAVIOR.md`, `enemies/ENEMIES.md`, `enemies/NEW_ENEMY.md`, `levels/LEVEL.md`

**Design principle:** enemy behavior is fixed per type across all levels. Difficulty comes from *composition* (which enemies, how many, spawn timing and direction) not per-level behavior changes. See `enemies/ENEMIES.md`.

---

## Priority 1 — Add Unused Enemies to Main Levels

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

## Enemy Focus Tuning (parking lot)

The Pass 1 focus rollout gave enemies `focus = 100` / `focus_regen = 10` as a "never a constraint" placeholder — player characters have focus as a meaningful resource (~30-60 max, 0.1-1.0 regen); enemies should eventually have **tighter, designed focus values** so high-cost enemy actions become a real pacing lever (e.g. "the boss can only Fire Burst every 8s because it runs out of focus"). Until then, enemy focus is effectively infinite and `focus_cost` on enemy-used actions (Sword Attack, Bow Attack, Seeking Bolt) doesn't gate anything for them.

When designing tighter enemy focus: pick values per-enemy based on their primary action cost and how often they should be able to cast it. Example: Skeleton Mage with Seeking Bolt (focus_cost = 2) at focus_regen 0.5 → caps casting at every 4s.

---

## Class Identity — Starting Relics (parking lot)

Each playable class gets a single class-specific starting relic to reinforce identity beyond skill kits (e.g. warrior's Regeneration Ring, priest's Hallowed Vestments). See [CAMPAIGN_DESIGN.md](levels/CAMPAIGN_DESIGN.md) for the design context.

**Future extension: multiple starting relics per class.** Once we have more relic content, each class could have a pool of N possible starting relics, with the actual one chosen per run (player choice or randomized). This gives runs more variety and allows alternate "builds" (e.g. a rogue with Shadowstep Boots plays differently from a rogue with Poison Coating). Held off until we have enough relics per class that the pool is non-trivial.

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
