# Sim Findings — Game Improvement Ideas

Things surfaced by running sim sessions that suggest **game-side improvements** (not tooling improvements). Add to this file whenever a sim session reveals something worth investigating in the game's design — skills, levels, behavior system, balance.

Each entry: brief observation + what motivated it. Cross-reference [`NEXT_STEPS.md`](../../NEXT_STEPS.md) when the design space is already captured there; don't duplicate.

---

## 2026-05-15 — first iteration loop on Knight + Cleric vs levels 1–5

Context: 5 attempts across levels 1, 2, 5 (the largest). Levels 1–2 won easily, level 5 (two_warrior_spawner_plus_two_archers) was lost in all 3 attempts at 16–18s with TOWER_DIED. See `tools/sim/configs/lvl1_attempt_1.json` etc. for raw runs.

### Skill design

- **Cleric has zero offensive options.** Starting kit is purely `Ally`-targeted (Heal, Magic Armor, Projectile Ward). Means clerics can't contribute at all to clearing threats — completely dependent on a partner. Even one low-tier offensive option (Smite? Holy Bolt? a melee retaliation?) would let clerics handle smaller threats while the partner focuses on bigger ones.
- **Cleric heal throughput may be too low for sustained damage.** Each defensive skill (Heal / Magic Armor / Projectile Ward) has an independent 5s cooldown, so they fire every ~5s individually — but Heal specifically only restores HP once per 5s. Against level 5 (6 simultaneous attackers), the per-second healing output couldn't outpace incoming damage. Either lower Heal's cooldown, raise its per-cast amount, or extend Magic Armor / Projectile Ward durations so the damage-mitigation buffs cover more of the gap between heals.

### Behavior system / targeting

These all point at the same design space — see [`NEXT_STEPS.md` "Behavior System — Design Ideas"](../../NEXT_STEPS.md) for the parking lot of possible solutions (richer target sorts, threat conditions, behavior tables with jumps, stamina pool). Specific observations from this session:

- **Sort orders couldn't prioritize archers over warriors.** Closest First / Farthest First weren't enough — with 6 melee + 4 ranged mixed across the map, neither sort consistently sent the knight to the archers. Using Farthest First made the knight chase one archer while warriors flanked from behind. Would have needed something like "Highest Threat (ranged)" or an explicit "attack-type filter."
- **No way to reactively defend the tower.** Tower took archer fire for 17s with no condition the cleric or knight could check to react ("tower under attack" → "stop what you're doing, kill archers").
- **First-match-wins ordering became fragile fast.** Cleric buff rotation (Projectile Ward → Magic Armor → Heal) + would-be offensive rules + would-be reactive rules all squeezed into one ordered list is brittle. The "behavior tables with jumps" idea in NEXT_STEPS would let each mode live in its own table.

### Level design

- **Level 5 may be unwinnable with 2 starting-kit characters.** All 3 attempts failed at 16–18s with TOWER_DIED. Two flank archers at (496, 59) and (496, 459) have clear line-of-sight to the tower at (235, 259); no decoration cover on the right half. Possible fixes:
  - Tower HP buff (currently 60, same as a character — see below)
  - Cover decoration on the right half to break archer line-of-sight
  - Reduce archer count (currently 2 spawners × 5 = 10 archers, which is most of the enemy pool)
  - Document this level as "requires relics or specific team comps"
- **All current stages use the same `forest_open_on_right_area` layout.** Already noted in [`NEXT_STEPS.md` Priority 1](../../NEXT_STEPS.md).

### Meta-progression / balance

- **Tower has the same HP as a character (60).** Makes it feel like a third character rather than a defended objective — and amplifies the level 5 archer problem above (60 HP vs 4 ranged attackers = dead in ~17s, regardless of player skill). Suggest substantially higher HP (200?) or scaling per level.

---

## 2026-05-16 — re-run Knight + Cleric vs lvl1, lvl5 with new tooling

Context: replay of the original session's setup, now with events digest + loss attribution + per-actor stats. Configs: `tools/sim/configs/lvl1_knight_cleric.json`, `lvl5_knight_cleric.json`, `lvl5_attempt2.json`. The richer summaries surfaced two new game-side observations beyond what the original session captured.

### Skill design — Cleric self-preservation

- **Cleric has zero self-preservation in her starting kit.** All her defensive skills (`Heal`, `Magic Armor`, `Projectile Ward`) target `Ally` — and the starting kit doesn't include `Self Or Ally`. So in any level where her starting position takes ranged fire, she can't ward / armor / heal *herself* — every buff goes onto the partner. In lvl5 she died at t=9.17 to archers, having never moved from her starting position, having dealt no damage, and having healed only 30 HP. Attempt 2 (stacking PW + Magic Armor before Heal) saved no one because both buffs landed on the Knight, not her.
  - Possible fixes: (a) add `Self Or Ally` to cleric's starting kit; (b) make her buffs default to self-targetable; (c) ensure stages with ranged threats don't have line-of-sight to cleric starting positions.
  - Related to the existing "Cleric has zero offensive options" entry above — together they show the cleric's starting kit is *fully* dependent on a partner being alive and nearby.

### Behavior system — Closest First creates positional convergence bias

- **Both characters with `Closest First` routed to the same cluster.** Knight + Cleric started at (331, 179) and (331, 339) respectively, but in lvl5 the Knight engaged ONLY upper-half enemies the entire run (every kill at y=99-135). The reason: the average distance from his starting position to "top spawn" was marginally shorter than to "bottom spawn", and once he moved up to attack, top became even closer. He never went south, leaving the bottom flank completely unanswered. The lower-cluster archers shot Puffin and the tower unopposed.
  - This isn't a bug — it's the predictable outcome of "Closest First" with a slight positional bias. But for stage designs with symmetric flanks it means the team only ever clears half the field.
  - Sort orders like `Highest Threat` (already in [`NEXT_STEPS.md` parking lot](../../NEXT_STEPS.md)) would help, but a simpler intermediate would be `Highest HP` or `Lowest HP` for finishing — still won't break the convergence though.
  - The fundamental gap: behaviors have no notion of *spatial coverage* or *area assignment* — there's no "you take the bottom, I take the top." Possible additions: a `Position Zone` filter on targets ("only target enemies in the bottom half") or a self-relative position concept ("only target enemies on the side of map closer to MY starting position").

---

## How to add entries

When a sim session reveals something:

1. **Tooling improvement?** → add to [`SIM.md`](SIM.md) "What's NOT in MVP" section, or open an issue
2. **Game improvement?** → add a dated entry here under a new H2
3. **Already discussed in [`NEXT_STEPS.md`](../../NEXT_STEPS.md)?** → point to it; don't restate the design space here. SIM_FINDINGS is about *what we observed*; NEXT_STEPS is the *design parking lot* of what to do about it.
4. Keep entries tight: observation in 1–2 lines, fix suggestions only if novel (not already in NEXT_STEPS)
5. Link to the relevant config/summary in `tools/sim/configs/` so future-you can re-run

If multiple sessions surface the same finding, consolidate into a single entry — don't duplicate.
