# LEVEL_NOTES: 02_warrior_press

**Difficulty band:** 2 (sibling of `02_corridor_pocket` on the other stage).

**Intent:** A d=2 sibling that tests *sustained melee commitment* rather than the pocket-prioritization that `02_corridor_pocket` tests. Player must hold the chokepoint through a grunt wave, then survive an armored warrior follow-up while the Cleric's healing keeps up. Beatable with the starting kit, but "attack closest" without any commit/heal structure will lose the tower.

## Composition

| Slot | Value |
|---|---|
| Stage | `forest_chokepoint.tscn` |
| Enemies | 5 Orc Grunts (HP 6) + 3 Orc Warriors (HP 10, armor 1) |
| Spawner | `(900, 260)` — corridor center (same as `01_grunt_rush`) |
| Timing | Grunts: `amount=5, interval=2.0, initial_delay=1.0` (wave 1, ~10s). Warriors: `amount=3, interval=2.5, initial_delay=9.0` (wave 2 overlaps tail of wave 1). |
| Tower | inherited |
| Victory/loss | inherited |

## Substrate assumptions

None new. Warrior is reused from the test/tutorial set; this is its first appearance in main_levels.

## Verification

Proven beatable by the pair in `tools/sim/behaviors/level/02_warrior_press_tight.json` (knight uses "Closest To Tower First", cleric uses Consecrate + heal lowest HP + Follow). Deterministic at ~29.4s.

The simpler "attack closest / heal closest" baseline LOSES the tower at ~65s — this is the smallest sophistication step that wins. Matches the d=2 expectation: starting kit suffices, but only with tighter rule construction.

## Quirks

- Warriors arriving while grunts are still alive means `Closest First` will keep swapping targets; `Lowest Health First` lets the player burn down warriors after grunts die.
- The chokepoint geometry neuters warrior armor a bit (line approach means only 1-2 warriors are in range at a time), so this is genuinely d=2 territory and not d=3.
- Stage variety vs `02_corridor_pocket`: both d=2, but different stages and different challenge axis (commitment vs prioritization).
