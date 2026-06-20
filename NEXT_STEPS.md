# Next Steps — Making the Game Fun

## Priority 1: Core Systems & The Campaign Spine
- **Map UI rendering:** The actual on-screen map (current node, future nodes, branching). Fundamental to the roguelike progression loop.
- **Campaign Backbone (Level Content):** We currently lack the full suite of levels. Target an intermediate milestone: **Build 3 levels for each difficulty (1-4), plus one difficulty 5 boss level**. 
  - Note: This involves utilizing unused enemies (Skeleton Warrior & Mage) as needed to create tactical puzzles. 
  - Note: This will likely require fixing/adding some behavior substrate first to ensure classes can beat them.
  - Note: Any new level we add (or existing levels lacking them) must include **sim pair files** for all valid character pairs.
- **Finish the Economy Loop (Chests + Gold UI):** The chest substrate is built but unused, and gold accumulates invisibly. Place chests in predictable campaign levels (e.g., Stage 3) and add a HUD element for gold.
- **Multiple behavior tables with jumps (function-like):** Might be needed as a core system to scale up to 15 levels. 
  - **Idea:** allow multiple named rule tables, plus a meta-skill that jumps to a different table, plus a condition to return to the main table.

## Priority 2: Content Validation
- **Smoke-test the new relics in actual play:** Validate the newly implemented relics (Vampire's Tooth, Overflowing Chalice, etc.) in a real fight via the sim or F6.

## Priority 3: Feature Expansion & UX Polish
- **More Reward Types:** Rest / Relic / Trainer is the shipped set. Add events, shops, etc. (Requires Map UI & Gold UI first).
- **UX Polish:** General UI cleanup across the board (e.g., the trainer overlay currently hides the party and breaks context).
- **Cosmetic Distinctions:** Visually distinguish class-relics vs earned-relics on the character card.

## Priority 4: Run Variety
- **Run Variety via Environmental Effects:** Infrastructure already exists: damage types and actor attributes support per-run modifiers (e.g. "Neverending Storm: fire damage halved, lightning doubled").

## Priority 5: "Icing on the Cake"
- **Difficulty Knob ("Monster Train" Style):** Elective per-stage difficulty modifiers (e.g., enemies spawn with armor/spikes) for better rewards.

---

## Key Files
| File | Purpose |
|---|---|
| `levels/LEVEL.md` | Level structure, spawner config, obstacles, NavMesh, what's not yet implemented |
| `enemies/ENEMIES.md` | Full roster: stats, behavior, current level usage |
| `behavior/BEHAVIOR.md` | Behavior system: available skills, params, action lifecycle |
| `AGENTS.md` | Project overview, component system, directory map |
