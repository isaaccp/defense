# LEVEL_NOTES: chokepoint_grunt_rush

**Position in campaign:** fight 1 (of planned 10).

**Intent:** Introduce the chokepoint stage. Show the player that enemies funnel through the central corridor and that basic "attack closest" wins. Trivially beatable with any 2-character starting-kit comp and minimal behavior tuning.

## Composition

| Slot | Value |
|---|---|
| Stage | `forest_chokepoint.tscn` |
| Enemies | 6 Orc Grunts (HP 6 each, no armor, melee) |
| Spawner position | (900, 260) — east end of corridor |
| Spawn timing | `amount=6, interval=2.0, initial_delay=1.0` — first spawn at t=1, last at t=11, 12s of spawning total |
| Tower | inherited 200 HP from stage |
| Victory/loss | inherited from base (KILL_ALL_ENEMIES / ALL_CHARACTERS_DIED + TOWER_DIED) |

## Substrate assumptions

None new — uses only what's already shipped post-Phase 1. Fight is designed for starting kits (no acquired-skill picks assumed).

## Verification

- **Mode A** (2026-05-16, seed=1): victory KILL_ALL_ENEMIES in 21.6s. Knight ended at 12/60 HP (20%). Cleric untouched at 50/50, healed 30 total. Tower untouched at 200/200. Summary: `tools/sim/configs/chokepoint_grunt_rush_mode_a.summary.json`.
- **Mode B**: pending — defer until at least 3 fights exist.
- **Mode C**: N/A for a single fight.

### Difficulty observation

Knight ending at 20% HP is closer to "tight win" than "trivial teaching fight" — the chokepoint funnels grunts into the Knight 1-2 at a time and damage stacks. For a fight 1 we may want this MORE friendly. Options if iterating:
- Drop grunt count 6 → 4 (most direct)
- Raise interval 2.0 → 3.0 (more space between waves for Cleric to heal)
- Both

Holding current values pending dev judgment — "tight teaching fight" vs "trivial teaching fight" is a taste call.

## Quirks

- Spawn timing means the wave is over by ~12s; if knight engages midway the level wraps fast.
- Grunts come single-file through the corridor — `Lowest Health First` will produce identical behavior to `Closest First` here since all grunts are at full HP when they arrive. AoE skills (Cleave, Sweeping Attack) are slightly wasted because targets don't cluster.
- This fight does NOT demand the stage's design tactic (the chokepoint matters more when there are multiple enemy types or when player must pick between flanks). It's a teaching fight, not a test fight.
