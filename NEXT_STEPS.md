# Next Steps — Making the Game Fun

## Priority 1: Core Systems & The Campaign Spine
- **Campaign Backbone (Level Content):** We currently lack the full suite of levels. Target an intermediate milestone: **Build 3 levels for each difficulty (1-4), plus one difficulty 5 boss level**. 
  - Note: This involves utilizing unused enemies (Skeleton Warrior & Mage) as needed to create tactical puzzles. 
  - Note: This will likely require fixing/adding some behavior substrate first to ensure classes can beat them.
  - Note: Any new level we add (or existing levels lacking them) must include **sim pair files** for all valid character pairs.
- **Reward Distribution Algorithm:** As we add more reward types, we need a smarter system to assign rewards across levels (e.g., guaranteeing a trainer every N levels) rather than pure randomness.
- **Finish the Economy Loop (Chests + Gold UI):** The chest substrate is built but unused, and gold accumulates invisibly. Place chests in predictable campaign levels (e.g., Stage 3) and add a HUD element for gold.
- **Multiple behavior tables with jumps (function-like):** Might be needed as a core system to scale up to 15 levels. 
  - **Idea:** allow multiple named rule tables, plus a meta-skill that jumps to a different table, plus a condition to return to the main table.

## Priority 2: Content Validation
- **Smoke-test the new relics in actual play:** Validate the newly implemented relics (Vampire's Tooth, Overflowing Chalice, etc.) in a real fight via the sim or F6.

## Priority 3: Feature Expansion & UX Polish
- **More Reward Types:** Rest / Relic / Trainer is the shipped set. Add events, shops, etc. (Requires Map UI & Gold UI first).
- **UX Polish:** General UI cleanup across the board (e.g., the trainer overlay currently hides the party and breaks context).
- **Cosmetic Distinctions:** Visually distinguish class-relics vs earned-relics on the character card.
- **Cosmetics (Map):** Support different `map_visuals` per level/stage rather than reusing the exact same forest map everywhere.

## Priority 4: Run Variety
- **Pre-Stage 1 (Stage 0):** Add a specialized reward stage before the first fight where players choose starting relics or environmental effects. Make sure the Map UI supports this easily.
- **Run Variety via Environmental Effects:** Infrastructure already exists: damage types and actor attributes support per-run modifiers (e.g. "Neverending Storm: fire damage halved, lightning doubled").

## Priority 5: "Icing on the Cake"
- **Difficulty Knob ("Monster Train" Style):** Elective per-stage difficulty modifiers (e.g., enemies spawn with armor/spikes) for better rewards.

---

## Context

The core problem is that levels feel samey: a plain field, identical enemy behavior, and no meaningful player decisions during setup. The infrastructure for fixing all of this exists — it mainly needs content and one missing UI feature.

**What was recently done:**
- Orc Shaman support enemy type implemented (healing allies + kiting/bolt kiting).
- Two Difficulty 4 levels (`04_shaman_chokepoint` and `04_orc_horde`) fully registered and verified.
- Created and verified 12 simulation behavior config JSONs for all 6 character pairings on both Level 4 levels.
- Engine robustness bug fixes: resolved Dead Target evaluation crashes, added AnimationComponent null guards, and aligned int vs float parameters in behavior loader.
- Meta-progression unlocks for Characters and Skill Trees.
- Standalone UI test scenes correctly populate and load data.
- Orc Archer now kites (Bow Attack min 100, Move Away max 120, Move To fallback)
- Orc Berserker added (`enemies/orc_berserker/orc_berserker.tscn`) — Charge → Sword Attack → Move To, speed=45, hp=8
- Enemy smoke tests added (`tests/enemies/enemy_smoke_test.gd`)
- Resource cost for skills (focus/stamina) implemented.
- Documentation: `behavior/BEHAVIOR.md`, `enemies/ENEMIES.md`, `enemies/NEW_ENEMY.md`, `levels/LEVEL.md`

**Design principle:** enemy behavior is fixed per type across all levels. Difficulty comes from *composition* (which enemies, how many, spawn timing and direction) not per-level behavior changes. See `enemies/ENEMIES.md`.

---

## Behavior System — Design Ideas (parking lot)

Captured from sim sessions (see `tools/sim/SIM_FINDINGS.md`) and design discussions. Not prioritized — these are pointers for future thinking, not specs.

### Richer target sorts and threat conditions
Current sort orders are limited to `Closest First` / `Farthest First`. Sims showed this is too coarse.
Suggested additions:
- **`Lowest Health First`**, **`Highest Threat`**, **`Highest Threat (ranged / melee)`**
- **Conditions like `Attacking Tower`** / **`Attacking Me`**

---

## Enemy Focus Tuning (parking lot)
When designing tighter enemy focus: pick values per-enemy based on their primary action cost and how often they should be able to cast it. Example: Skeleton Mage with Seeking Bolt (focus_cost = 2) at focus_regen 0.5 → caps casting at every 4s.

---

## Class Identity — Starting Relics (parking lot)
Each playable class gets a single class-specific starting relic to reinforce identity beyond skill kits.

---

## Key Files
| File | Purpose |
|---|---|
| `levels/LEVEL.md` | Level structure, spawner config, obstacles, NavMesh, what's not yet implemented |
| `enemies/ENEMIES.md` | Full roster: stats, behavior, current level usage |
| `behavior/BEHAVIOR.md` | Behavior system: available skills, params, action lifecycle |
| `AGENTS.md` | Project overview, component system, directory map |
