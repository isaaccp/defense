# LEVEL_NOTES: 01_archer_rush

**Difficulty band:** 1 (sibling of `01_grunt_rush` on the other stage).

**Intent:** A d=1 sibling that swaps the enemy roster. Same "rush from the main spawner, no flank pressure" challenge as `01_grunt_rush`, but with archers instead of grunts. Beatable with the starting kit — `Move To closest Enemy` then `Sword Attack` still works.

## Composition

| Slot | Value |
|---|---|
| Stage | `forest_ambush.tscn` (no pocket activity) |
| Enemies | 5 Orc Archers (HP 5, no armor, bow attack range 100–300) |
| Spawner | `(650, 260)` — main corridor anchor |
| Timing | `amount=5, interval=2.5, initial_delay=1.0` — wave spans ~12s |
| Tower | inherited from stage |
| Victory/loss | inherited |

## Substrate assumptions

None new. The archers' kiting is partly neutralized by the open corridor — they can fire from farther back than grunts close, but the player can still close in (their `min_distance=100` means they can't shoot point-blank when chased).

## Verification

Proven beatable by the pair in `tools/sim/behaviors/level/01_archer_rush_baseline.json` (baseline "attack closest / heal closest" comp, same as `01_grunt_rush_baseline`).

Sim is non-deterministic on this level due to archer `Move Away` (see SIM_FINDINGS 2026-06-08): elapsed time ranged 34–84s across runs. Always won within 90s budget.

## Quirks

- Archers will start shooting before melee characters close the distance, so the tower takes some early chip damage. Acceptable at d=1.
- Different damage type from `01_grunt_rush` (piercing vs slashing) — exposes the player to the damage-type concept early.
- `Closest First` is functionally identical to `Lowest Health First` here (uniform HP arriving in a line).
